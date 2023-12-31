#!/bin/bash
#
#  Licensed under the Apache License, Version 2.0 (the "License"); you may
#  not use this file except in compliance with the License. You may obtain
#  a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#  License for the specific language governing permissions and limitations
#  under the License.

set -e

HELM_CHART="$1"

: "${HELM_CHART_ROOT_PATH:="../openstack-helm-infra"}"
: "${OPENSTACK_RELEASE:="2023.1"}"
: "${CONTAINER_DISTRO_NAME:="ubuntu"}"
: "${CONTAINER_DISTRO_VERSION:="focal"}"
: "${FEATURE_GATES:="apparmor"}"
OSH_INFRA_FEATURE_MIX="${FEATURE_GATES},${OPENSTACK_RELEASE},${CONTAINER_DISTRO_NAME}_${CONTAINER_DISTRO_VERSION},${CONTAINER_DISTRO_NAME}"

function echoerr () {
  echo "$@" 1>&2;
}

function generate_awk_exp_from_mask () {
  local POSITION=1
  for VALUE in $@; do
    [ "${VALUE}" -eq 1 ] && echo -n "print \$${POSITION};"
    POSITION=$((POSITION+1))
  done
  echo -e "\n"
}

function combination () {
  POWER=$((2**$#))
  BITS="$(awk "BEGIN { while (c++ < $#) printf \"0\" }")"
  while [ "${POWER}" -gt 1 ];do
    POWER=$((POWER-1))
    BIN="$(bc <<< "obase=2; ${POWER}")"
    MASK="$(echo "${BITS}" | sed -e "s/0\{${#BIN}\}$/$BIN/" | grep -o .)"
    #NOTE: This line is odd, but written to support both BSD and GNU utils
    awk -v ORS="-" "{$(generate_awk_exp_from_mask "$MASK")}" <<< "$@" | awk 1 | sed 's/-$//'
  done
}

function override_file_args () {
  OVERRIDE_ARGS=""
  echoerr "We will attempt to use values-override files with the following paths:"
  for FILE in $(combination ${1//,/ } | uniq | tac); do
    FILE_PATH="${HELM_CHART_ROOT_PATH}/${HELM_CHART}/values_overrides/${FILE}.yaml"
    if [ -f "${FILE_PATH}" ]; then
      OVERRIDE_ARGS+=" --values=${FILE_PATH} "
    fi
      echoerr "${FILE_PATH}"
  done
  echo "${OVERRIDE_ARGS}"
}

echoerr "We are going to deploy the service ${HELM_CHART} using ${CONTAINER_DISTRO_NAME} (${CONTAINER_DISTRO_VERSION}) distribution containers."
source ${HELM_CHART_ROOT_PATH}/tools/deployment/common/env-variables.sh
override_file_args "${OSH_INFRA_FEATURE_MIX}"
