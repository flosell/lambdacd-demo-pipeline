#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" ; pwd -P)
CONTAINER_NAME="lambdacd-pipeline"

goal_clean() {
  lein clean
}

goal_build-jar() {
  lein uberjar
}

goal_build-container() {
  docker build . -t ${CONTAINER_NAME}
}
goal_run-container() {
  docker run --rm --name pipeline -it -p 8080:8080 ${CONTAINER_NAME}
}

goal_build() {
  goal_build-jar
  goal_build-container
}

goal_dev-up() {
  goal_build
  goal_run-container
}

if type -t "goal_$1" &>/dev/null; then
  pushd "${SCRIPT_DIR}" >/dev/null
    "goal_$1" "${@:2}"
  popd "${SCRIPT_DIR}" >/dev/null
else
  echo "usage: $0 <goal>
goal:
    build-jar       -- build an uberjar ready to run
    build-container -- build a container for the pipeline
    build           -- run a complete build

    dev-up          -- run the lambdacd-environment locally

    clean           -- clean up working directory"
  exit 1
fi
