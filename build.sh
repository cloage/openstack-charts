#!/bin/bash

set -ex

export OPENSTACK_RELEASE=2023.2
export CONTAINER_DISTRO_NAME=ubuntu
export CONTAINER_DISTRO_VERSION=jammy

cd upstream/openstack-helm/
git pull https://opendev.org/openstack/openstack-helm.git
make all
mv *.tgz ../../charts/


cd ../openstack-helm-infra
git pull https://opendev.org/openstack/openstack-helm-infra.git
make ceph-mon
make ceph-provisioners
make mariadb
make rabbitmq
make memcached
make openvswitch
make libvirt
mv *.tgz ../../charts/

cd ../../charts/
helm repo index ./ --url https://cloage.github.io/openstack-charts

