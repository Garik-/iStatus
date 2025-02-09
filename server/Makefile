build:
	rm udp_server_arm64
	GOOS=linux GOARCH=arm64 go build -o udp_server_arm64 .

publish: build
	scp udp_server_arm64 xakep@192.168.1.10:/home/xakep/code/tmp/