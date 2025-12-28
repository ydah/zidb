.PHONY: docker-build docker-run docker-shell build test clean target

docker-build:
	docker compose build

docker-shell:
	docker compose run --rm zdb bash

docker-run:
	docker compose run --rm zdb bash -c "make target && zig build && ./zig-out/bin/zidb ./targets/hello"

build:
	zig build

target:
	mkdir -p targets
	zig build-exe targets/hello.zig -femit-bin=targets/hello

test:
	zig build test

clean:
	rm -rf zig-out .zig-cache targets/hello

help:
	@echo "Docker commands (run on host):"
	@echo "  make docker-build  - Build Docker image"
	@echo "  make docker-shell  - Enter container shell"
	@echo "  make docker-run    - Build and run in container"
	@echo ""
	@echo "Dev commands (run in container):"
	@echo "  make build   - Build the debugger"
	@echo "  make target  - Build test target"
	@echo "  make test    - Run tests"
	@echo "  make clean   - Clean build artifacts"
