//go:build windows

package main

import (
	"syscall"
	"time"
	"unsafe"
)

// En Windows, time.Now avanza a saltos de 0,5 a 1 ms según la resolución del
// temporizador del sistema. La comparativa de granularidad mide total_s con
// QueryPerformanceCounter, el mismo reloj que usan las versiones C.
const preciseClockName = "QueryPerformanceCounter"

var (
	kernel32                  = syscall.NewLazyDLL("kernel32.dll")
	procQueryPerformanceCount = kernel32.NewProc("QueryPerformanceCounter")
	procQueryPerformanceFreq  = kernel32.NewProc("QueryPerformanceFrequency")
	preciseFrequency          = func() int64 {
		var frequency int64
		procQueryPerformanceFreq.Call(uintptr(unsafe.Pointer(&frequency)))
		return frequency
	}()
)

func preciseNow() int64 {
	var counter int64
	procQueryPerformanceCount.Call(uintptr(unsafe.Pointer(&counter)))
	return counter
}

func preciseSince(start int64) time.Duration {
	return time.Duration(float64(preciseNow()-start) * 1e9 / float64(preciseFrequency))
}
