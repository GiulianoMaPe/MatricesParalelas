package main

import (
	"fmt"
	"os"
	"runtime/debug"
)

type environmentInfo struct {
	commit, hostname, cpuModel, osVersion string
	totalMemory, availableMemory          uint64
}

func collectEnvironment() (environmentInfo, error) {
	info, err := systemEnvironment()
	if err != nil {
		return info, fmt.Errorf("datos del equipo: %w", err)
	}
	info.hostname, err = os.Hostname()
	if err != nil || info.hostname == "" {
		return info, fmt.Errorf("no se pudo obtener el nombre del equipo")
	}
	build, ok := debug.ReadBuildInfo()
	if ok {
		for _, setting := range build.Settings {
			if setting.Key == "vcs.revision" {
				info.commit = setting.Value
				break
			}
		}
	}
	if len(info.commit) < 7 || len(info.commit) > 40 {
		return info, fmt.Errorf("falta el commit de compilación; compilar desde el repositorio con go build -buildvcs=true")
	}
	return info, nil
}
