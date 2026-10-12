package main

import (
	"encoding/binary"
	"fmt"
	"strconv"
	"strings"
	"syscall"
	"unicode/utf16"
	"unsafe"
)

func registryValue(path, name string) ([]byte, uint32, error) {
	keyName, err := syscall.UTF16PtrFromString(path)
	if err != nil {
		return nil, 0, err
	}
	var key syscall.Handle
	if err := syscall.RegOpenKeyEx(syscall.HKEY_LOCAL_MACHINE, keyName, 0, syscall.KEY_QUERY_VALUE, &key); err != nil {
		return nil, 0, err
	}
	defer syscall.RegCloseKey(key)
	valueName, err := syscall.UTF16PtrFromString(name)
	if err != nil {
		return nil, 0, err
	}
	var kind, size uint32
	if err := syscall.RegQueryValueEx(key, valueName, nil, &kind, nil, &size); err != nil {
		return nil, 0, err
	}
	if size == 0 {
		return nil, kind, fmt.Errorf("valor vacío del registro: %s", name)
	}
	data := make([]byte, size)
	if err := syscall.RegQueryValueEx(key, valueName, nil, &kind, &data[0], &size); err != nil {
		return nil, kind, err
	}
	return data[:size], kind, nil
}

func registryString(path, name string) (string, error) {
	data, kind, err := registryValue(path, name)
	if err != nil {
		return "", err
	}
	if kind != syscall.REG_SZ || len(data)%2 != 0 {
		return "", fmt.Errorf("valor del registro no es texto: %s", name)
	}
	units := make([]uint16, len(data)/2)
	for i := range units {
		units[i] = binary.LittleEndian.Uint16(data[i*2:])
	}
	value := strings.TrimSpace(strings.TrimRight(string(utf16.Decode(units)), "\x00"))
	if value == "" {
		return "", fmt.Errorf("valor vacío del registro: %s", name)
	}
	return value, nil
}

// MEMORYSTATUSEX: DWORD length/load y siete campos de tamaño DWORDLONG.
type memoryStatusEx struct {
	length, load                                       uint32
	totalPhys, availPhys, totalPageFile, availPageFile uint64
	totalVirtual, availVirtual, availExtendedVirtual   uint64
}

func systemEnvironment() (environmentInfo, error) {
	var info environmentInfo
	var err error
	info.cpuModel, err = registryString(`HARDWARE\DESCRIPTION\System\CentralProcessor\0`, "ProcessorNameString")
	if err != nil {
		return info, err
	}
	const osKey = `SOFTWARE\Microsoft\Windows NT\CurrentVersion`
	product, err := registryString(osKey, "ProductName")
	if err != nil {
		return info, err
	}
	build, err := registryString(osKey, "CurrentBuildNumber")
	if err != nil {
		return info, err
	}
	buildNumber, err := strconv.Atoi(build)
	if err != nil {
		return info, err
	}
	// Windows 11 puede conservar "Windows 10" en ProductName del registro.
	if buildNumber >= 22000 {
		product = strings.Replace(product, "Windows 10", "Windows 11", 1)
	}
	if data, kind, err := registryValue(osKey, "UBR"); err == nil && kind == syscall.REG_DWORD && len(data) == 4 {
		build += fmt.Sprintf(".%d", binary.LittleEndian.Uint32(data))
	}
	info.osVersion = product + " build " + build
	status := memoryStatusEx{}
	status.length = uint32(unsafe.Sizeof(status))
	proc := syscall.NewLazyDLL("kernel32.dll").NewProc("GlobalMemoryStatusEx")
	ok, _, callErr := proc.Call(uintptr(unsafe.Pointer(&status)))
	if ok == 0 {
		return info, callErr
	}
	if status.totalPhys == 0 {
		return info, fmt.Errorf("Windows no informó la RAM visible")
	}
	info.totalMemory, info.availableMemory = status.totalPhys, status.availPhys
	return info, nil
}
