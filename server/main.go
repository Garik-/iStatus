package main

import (
	"context"
	"flag"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"golang.org/x/sync/errgroup"
)

func main() {
	addr := flag.String("addr", "192.168.1.255:9999", "UDP server port")
	interval := flag.Duration("i", 2*time.Second, "measure interval")
	flag.Parse()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	g, gCtx := errgroup.WithContext(ctx)

	service := &service{
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
