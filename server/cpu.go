package main

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

const cpuFile = "/proc/stat"

func getCPUTimes() ([]int, error) {
	file, err := os.Open(cpuFile)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "cpu ") {
			fields := strings.Fields(line)[1:]
			cpuTimes := make([]int, len(fields))
			for i, field := range fields {
				cpuTimes[i], err = strconv.Atoi(field)
				if err != nil {
					return nil, err
				}
			}
			return cpuTimes, nil
		}
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return nil, errors.New("CPU info not found")
}

func calculateCPUUsage(ctx context.Context, interval time.Duration) (string, error) {
	times1, err := getCPUTimes()
	if err != nil {
		return "", err
	}

	select {
	case <-ctx.Done():
		return "", ctx.Err()
	case <-time.After(interval):
		// continue the loop
	}

	times2, err := getCPUTimes()
	if err != nil {
		return "", err
	}

	delta := make([]int, len(times1))
	totalTime := 0
	idleTime := 0

	for i := range times1 {
		delta[i] = times2[i] - times1[i]
		totalTime += delta[i]
	}

	if len(delta) > 4 { // idle = idle + iowait
		idleTime = delta[3] + delta[4]
	}

	if totalTime == 0 {
		return "", nil
	}

	cpuUsage := 100 * float64(totalTime-idleTime) / float64(totalTime)
	return fmt.Sprintf("%.2f%%", cpuUsage), nil
}
