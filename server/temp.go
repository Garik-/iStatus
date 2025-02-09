package main

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

const tempFile = "/sys/class/thermal/thermal_zone0/temp"

func readTemperature() (string, error) {
	data, err := os.ReadFile(tempFile)
	if err != nil {
		return "", err
	}
	tempStr := strings.TrimSpace(string(data))
	tempMilli, err := strconv.Atoi(tempStr)
	if err != nil {
		return "", err
	}

	return fmt.Sprintf("%.1f°C", float64(tempMilli)/1000.0), nil
}
