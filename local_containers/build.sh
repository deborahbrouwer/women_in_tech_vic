
#!/bin/bash

set -ex

function cleanup() {
  echo "Return ownership of bound directories back to container host."
  chown -R root:root /app
  exit
}
trap cleanup SIGTERM SIGINT

info() {
    # green color
    echo -e "\033[32m$1\033[0m" >&2
}


rm -f /wit_shared/run_app.sh
cp /app/local_containers/run_app.sh /wit_shared/run_app.sh

info "Fetching dependencies..."
mix deps.get

info "Deploying assets..."
mix assets.deploy

info "Compiling..."
mix compile --force

info "Building binaries..."
mix release --force --overwrite --path /wit_shared

cleanup