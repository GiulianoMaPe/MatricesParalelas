//go:build !windows

package main

import "time"

const preciseClockName = "time.Now"

var clockOrigin = time.Now()

func preciseNow() int64 { return int64(time.Since(clockOrigin)) }

func preciseSince(start int64) time.Duration { return time.Duration(preciseNow() - start) }
