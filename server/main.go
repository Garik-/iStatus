package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"golang.org/x/sync/errgroup"
)

const tempFile = "/sys/class/thermal/thermal_zone0/temp"

type Service struct {
	broadcastUDPAddr *net.UDPAddr
	conn             net.PacketConn

	initialized chan struct{}
}

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

	return fmt.Sprintf("%.1f'C", float64(tempMilli)/1000.0), nil
}

func (s *Service) process(ctx context.Context, interval time.Duration) error {
	<-s.initialized // blocks

	for {
		temp, err := readTemperature()
		if err != nil {
			return fmt.Errorf("read temperature: %w", err)
		}

		_, err = s.writeBroadcast([]byte(temp))
		if err != nil {
			return fmt.Errorf("write broadcast: %w", err)
		}

		log.Println(temp)

		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(interval):
			// continue the loop
		}
	}
}

func (s *Service) writeBroadcast(message []byte) (int, error) {
	if s.conn == nil || s.broadcastUDPAddr == nil {
		panic("service is not running")
	}

	return s.conn.WriteTo(message, s.broadcastUDPAddr)
}

func (s *Service) run(ctx context.Context, UDPAddr string) error {
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

func main() {
	addr := flag.String("addr", "192.168.1.255:9999", "UDP server port")
	interval := flag.Duration("i", 2*time.Second, "measure interval")
	flag.Parse()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	g, gCtx := errgroup.WithContext(ctx)

	service := &Service{
		initialized: make(chan struct{}),
	}

	g.Go(func() error {
		return service.run(gCtx, *addr)
	})

	g.Go(func() error {
		return service.process(gCtx, *interval)
	})

	if err := g.Wait(); err != nil {
		log.Println(err)
	}

	log.Println("done")
}
