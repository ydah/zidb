#!/bin/bash

set -e

IMAGE_NAME="zdb-dev"
CONTAINER_NAME="zdb-dev-container"

if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo "Building Docker image..."
    docker build -t "$IMAGE_NAME" .
fi

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    docker rm -f "$CONTAINER_NAME" &> /dev/null || true
fi

echo "Starting development container..."
echo ""

docker run -it --rm \
    --name "$CONTAINER_NAME" \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    -v "$(pwd)":/workspace \
    "$IMAGE_NAME" \
    "$@"
