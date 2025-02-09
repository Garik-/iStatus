build:
	rm istatus
	GOOS=linux GOARCH=arm64 go build -o istatus .

publish: build
	scp istatus xakep@192.168.1.10:/home/xakep/bin