package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"time"
)

type service struct {
	broadcastUDPAddr *net.UDPAddr
	conn             net.PacketConn

	initialized chan struct{}
}

type Packet struct {
	Temp string   `json:"temp"`
	CPU  string   `json:"cpu"`
	Mem  *MemInfo `json:"mem"`
}

func encodePacket(cpuUsage string, temp string, meminfo *MemInfo) ([]byte, error) {
	p := Packet{
		CPU:  cpuUsage,
		Temp: temp,
		Mem:  meminfo,
	}

	return json.Marshal(p)
}

func (s *service) process(ctx context.Context, interval time.Duration) error {
	<-s.initialized // blocks

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		cpuUsage, err := calculateCPUUsage(ctx, interval)
		if err != nil {
			return fmt.Errorf("calculate CPU usage: %w", err)
		}

		temp, err := readTemperature()
		if err != nil {
			return fmt.Errorf("read temperature: %w", err)
		}

		meminfo, err := getMemoryUsage()
		if err != nil {
			return fmt.Errorf("memory usage: %w", err)
		}

		message, err := encodePacket(cpuUsage, temp, meminfo)
		if err != nil {
			return fmt.Errorf("encode packet: %w", err)
		}

		_, err = s.writeBroadcast(message)
		if err != nil {
			return fmt.Errorf("write broadcast: %w", err)
		}

		log.Println(string(message))
	}
}

func (s *service) writeBroadcast(message []byte) (int, error) {
	if s.conn == nil || s.broadcastUDPAddr == nil {
		panic("service is not running")
	}

	return s.conn.WriteTo(message, s.broadcastUDPAddr)
}

func (s *service) run(ctx context.Context, UDPAddr string) error {
	_, port, err := net.SplitHostPort(UDPAddr)
	if err != nil {
		return fmt.Errorf("split host port: %w", err)
	}

	conn, err := net.ListenPacket("udp4", ":"+port)
	if err != nil {
		return fmt.Errorf("listen packet: %w", err)
	}
	defer conn.Close()

	addr, err := net.ResolveUDPAddr("udp4", UDPAddr)
	if err != nil {
		return fmt.Errorf("resolving broadcast address: %w", err)
	}

	s.broadcastUDPAddr = addr
	s.conn = conn

	log.Printf("UDP server is running, listens on %s, and sends a broadcast...", UDPAddr)

	close(s.initialized)
	<-ctx.Done()

	return nil
}
