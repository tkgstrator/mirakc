.PHONY: build
build:
	docker build -t tkgling/mirakc:latest . --push

.PHONY: up
up:
	docker compose up