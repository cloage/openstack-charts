#!/bin/bash

#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

set -xe

#NOTE: Lint and package chart
make kibana

: ${OSH_INFRA_EXTRA_HELM_ARGS_KIBANA:="$(./tools/deployment/common/get-values-overrides.sh kibana)"}

#NOTE: Deploy command
helm upgrade --install kibana ./kibana \
  --namespace=osh-infra \
  --set network.kibana.ingress.classes.namespace=nginx-osh-infra \
  ${OSH_INFRA_EXTRA_HELM_ARGS} \
  ${OSH_INFRA_EXTRA_HELM_ARGS_KIBANA}

#NOTE: Wait for deploy
./tools/deployment/common/wait-for-pods.sh osh-infra
