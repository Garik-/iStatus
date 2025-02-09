package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

const memFile = "/proc/meminfo"

type MemInfo struct {
	Total     int    `json:"total"`
	Used      int    `json:"used"`
	Available int    `json:"available"`
	Usage     string `json:"usage"`
}

func tokB(num int, unit string) int {
	switch unit {
	case "B":
		num = num / 1024 // Байты в килобайты
	case "MB":
		num = num * 1024 // Мегабайты в килобайты
	case "GB":
		num = num * 1024 * 1024 // Гигабайты в килобайты
	}

	return num
}

func parseMemInfo() (map[string]int, error) {
	meminfo := make(map[string]int)

	file, err := os.Open(memFile)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()

		parts := strings.SplitN(line, ":", 2)
		if len(parts) < 2 {
			continue
		}

		key := strings.TrimSpace(parts[0])
		value := strings.Fields(strings.TrimSpace(parts[1]))

		num, err := strconv.Atoi(value[0])
		if err != nil {
			continue
		}

		if len(value) == 2 {
			unit := value[1]
			meminfo[key] = tokB(num, unit)
		} else if len(value) == 1 {
			meminfo[key] = num
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return meminfo, nil
}

func getMemoryUsage() (*MemInfo, error) {
	meminfo, err := parseMemInfo()
	if err != nil {
		return nil, err
	}

	memUsed := meminfo["MemTotal"] - meminfo["MemFree"] - meminfo["Buffers"] - meminfo["Cached"]

	m := &MemInfo{
		Total:     meminfo["MemTotal"],
		Available: meminfo["MemAvailable"],
		Used:      meminfo["MemTotal"] - meminfo["MemFree"] - meminfo["Buffers"] - meminfo["Cached"],
		Usage:     fmt.Sprintf("%.2f%%", float64(memUsed)/float64(meminfo["MemTotal"])*100),
	}

	return m, nil
}
