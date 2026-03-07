build:
	rm -f istatus
	GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o istatus .

publish: build
	scp istatus xakep@192.168.1.10:/home/xakep/bin
	scp istatus.service xakep@192.168.1.10:/home/xakep/bin
