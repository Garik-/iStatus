build:
	GOOS=linux GOARCH=arm64 go build -o udp_server_arm64 main.go

publish: build
	scp udp_server_arm64 xakep@192.168.1.10:/home/xakep/code/tmp/