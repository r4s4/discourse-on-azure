#!/usr/bin/env bash

set -euo pipefail

echo "$REGISTRY_PASSWORD" | docker login -u "REGISTRY_USERNAME" --password-stdin ghcr.io
config=web_only
version=stable
build_root="build-root"
git clone --depth=1 https://github.com/discourse/discourse_docker "$build_root"
sed -i "s/__DISCOURSE_VERSION__/$version/g" "$config.yml"
cp "$config.yml" "$build_root/containers"
cd "$build_root"
docker compose up -d

./launcher bootstrap "$config" --docker-args "--net=discourse --mount type=tmpfs,destination=/shared --mount type=tmpfs,destination=/var/log"
build_image_name="local_discourse/$config:latest"
deploy_image_name="ghcr.io/pschichtel/discourse:$version-$(tr _ - <<< "$config")"

docker compose down
set -x
docker image tag "$build_image_name" "$deploy_image_name"
docker image rm "$build_image_name"
docker image push "$deploy_image_name"
