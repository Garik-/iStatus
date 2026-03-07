# Rust target
TARGET = aarch64-unknown-linux-gnu

# Режим сборки
PROFILE = release

# Директория для итогового бинарника на хосте
DIST = dist

# Кэш Cargo
CARGO_CACHE = $(HOME)/.cargo

# Получаем имя пакета из Cargo.toml автоматически
BINARY := istatus

.PHONY: all build clean

all: deploy

# Сборка через Docker с кэшем зависимостей
build:
	@mkdir -p $(DIST)
	@echo "Building $(BINARY) for $(TARGET) via Docker with cached dependencies..."
	docker run --rm \
		-v $(PWD):/usr/src/app \
		-v $(CARGO_CACHE)/registry:/usr/local/cargo/registry \
		-v $(CARGO_CACHE)/git:/usr/local/cargo/git \
		-w /usr/src/app \
		rust:latest \
		bash -c "\
			rustup target add $(TARGET) && \
			apt-get update && apt-get install -y gcc-aarch64-linux-gnu musl-tools jq && \
			cargo build --release --target $(TARGET) \
		"
	@cp target/$(TARGET)/$(PROFILE)/$(BINARY) $(DIST)/

# Очистка проекта
clean:
	cargo clean
	rm -rf $(DIST)
	@echo "Cleaned."

deploy: build
	scp $(DIST)/$(BINARY) xakep@raspberrypi.local:/home/xakep/bin
