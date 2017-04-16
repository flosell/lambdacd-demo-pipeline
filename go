#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" ; pwd -P)
CONTAINER_NAME="lambdacd-pipeline"

echob() {
  echo -e "\033[1m$1\033[0m"
}


goal_clean() {
  lein clean
}

goal_build-jar() {
  lein uberjar
}

goal_build-container() {
  docker build -t ${CONTAINER_NAME} .
}

get_new_container_port() {
  if docker ps --filter 'name=pipeline-' | grep -q 0.0.0.0:8080; then
    echo 8081
  else
    echo 8080
  fi
}

goal_run-container() {
  if [ "${DEV_MODE}" == true ]; then
    dev_args="-v ${SCRIPT_DIR}:/project -e DEV_PIPELINE_PROJECT_LOCATION=/project"
  else
    dev_args=""
  fi

  docker run \
    -d \
    --rm \
    --name pipeline-$(date +%s) \
    -it \
    -p $(get_new_container_port):8080 \
    -v /var/run/docker.sock:/var/run/docker.sock:rw \
    --group-add 50 --group-add 992 ${dev_args} \
    ${CONTAINER_NAME}
}

goal_stop-old-container() {
  pipeline_container_ids=$(docker ps --filter 'name=pipeline-' -q)
  if [ $(wc -l <<< "${pipeline_container_ids}") -gt 1 ]; then
    echob "Found more than one running pipeline container, stopping oldest..."
    docker stop $(tail -n 1 <<< "${pipeline_container_ids}")
  else
    echob "Did not find more than one container, not stopping anything."
  fi
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
  popd >/dev/null
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
