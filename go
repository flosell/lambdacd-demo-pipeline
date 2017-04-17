#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" ; pwd -P)
CONTAINER_NAME="lambdacd-pipeline"

if [ -f "${SCRIPT_DIR}/.go-config" ]; then
  source "${SCRIPT_DIR}/.go-config"
fi

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

get_new_container_color() {
  if docker ps --filter 'name=pipeline-' | grep -q green; then
    echo "blue"
  else
    echo "green"
  fi
}

ensure_docker_network() {
  docker network ls | grep -q lambdacd || docker network create lambdacd --subnet 172.18.0.0/16
}

get_ip() {
  if [ "${1}" == "green" ]; then
    echo "172.18.0.10"
  else
    echo "172.18.0.11"
  fi
}


goal_run-container() {
  if [ "${DEV_MODE}" == true ]; then
    dev_args="-v ${SCRIPT_DIR}:/project -e DEV_PIPELINE_PROJECT_LOCATION=/project"
  else
    dev_args=""
  fi

  ensure_docker_network

  color=$(get_new_container_color)
  ip=$(get_ip ${color})

  docker run \
    -d \
    --rm \
    --network lambdacd \
    --ip "${ip}" \
    --name "pipeline-${color}" \
    -it \
    -v /var/run/docker.sock:/var/run/docker.sock:rw \
    --group-add 50 --group-add 992 ${dev_args} \
    ${CONTAINER_NAME}
}

function dockerWorking() {
    docker pull ${DEMO_IMAGE_URL} > /dev/null
}
function ecrLogin() {
     echob "Not logged into ECR yet, logging in"
     eval "$(aws ecr get-login --region eu-central-1)"
}

goal_push-containers() {
  if [ -z "${DEMO_IMAGE_URL}" ]; then
    echo "Needs DEMO_IMAGE_URL"
    exit 1
  fi

  dockerWorking || ecrLogin


  docker tag ${CONTAINER_NAME}:latest ${DEMO_IMAGE_URL}:latest
  docker push ${DEMO_IMAGE_URL}:latest
}

goal_run-lb() {
  ensure_docker_network

  docker run -p 8000:8000 \
             --name lambdacd-lb \
             --network lambdacd \
             --rm \
             --volume ${SCRIPT_DIR}/lb/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg \
             haproxy:1.7-alpine
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
    run-lb          -- run a loadbalancer so blue-green deploying new pipelines works

    clean           -- clean up working directory"
  exit 1
fi
