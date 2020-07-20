#!/usr/bin/env bash

echo "geneating keys for concourse...."

WORK_DIR="$PWD"

docker run --rm -v "$WORK_DIR/keys":/keys concourse/concourse \
  generate-key -t rsa -f /keys/session_signing_key

docker run --rm -v "$WORK_DIR/keys":/keys concourse/concourse \
  generate-key -t ssh -f /keys/tsa_host_key

docker run --rm -v "$WORK_DIR/keys":/keys concourse/concourse \
  generate-key -t ssh -f /keys/worker_key

cp ./keys/worker_key.pub ./keys/authorized_worker_keys
#cp ./web/tsa_host_key.pub ./worker

echo "....finished!"