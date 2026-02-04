#!/bin/bash
set -euo pipefail

# 可通过环境变量 PLATFORM 设置目标平台，例如: PLATFORM=linux/arm64
PLATFORM=${PLATFORM:-linux/amd64}

IMAGE_BUILD_NAME=fabric-console:latest

# Info about the build is saved in tags on the docker image
COMMIT=$(git rev-parse --short HEAD)
GIT_TAG=$(git describe --tags || true)
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # Where the script lives

echo "Building ${IMAGE_BUILD_NAME} for platform ${PLATFORM}"
echo "Found tag ${GIT_TAG}"

# 使用 buildx 单架构构建并加载到本地 docker（--load 只能用于单个平台）
docker buildx build \
    --platform "${PLATFORM}" \
    --load \
    -t "${IMAGE_BUILD_NAME}" \
    --build-arg BUILD_ID="${COMMIT}" \
    --build-arg BUILD_DATE="${BUILD_DATE}" \
    --build-arg CONSOLE_TAG="${GIT_TAG}" \
    --pull -f "${SRC_DIR}/console/Dockerfile" "${SRC_DIR}/../packages/."

# 打 tag，保持原有行为（GHCR 标签）
docker tag "${IMAGE_BUILD_NAME}" ghcr.io/hyperledger-labs/fabric-console:latest
if [[ -n "${GIT_TAG}" ]]; then
    echo "Creating tagged image ${GIT_TAG}:"
    docker tag "${IMAGE_BUILD_NAME}" ghcr.io/hyperledger-labs/fabric-console:"${GIT_TAG}"
fi

echo "Build complete for ${PLATFORM}"
