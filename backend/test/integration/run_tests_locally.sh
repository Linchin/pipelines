#!/bin/bash
# Copyright 2018-2023 The Kubeflow Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

if [ -z "${NAMESPACE}" ]; then
    echo "NAMESPACE env var is not provided, please set it to your KFP namespace"
    exit
fi

echo "The api integration tests run against the cluster your kubectl communicates to.";
echo "It's currently '$(kubectl config current-context)'."
echo "WARNING: this will clear up all existing KFP data in this cluster."
read -r -p "Are you sure? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        ;;
    *)
        exit
        ;;
esac

if [ "$1" == "postgres" ]; then
    echo "Starting PostgreSQL DB port forwarding..."
    kubectl -n "$NAMESPACE" port-forward svc/postgres-service 5432:5432 --address="127.0.0.3" & PORT_FORWARD_PID=$!
    # wait for kubectl port forward
    sleep 10
    echo "Starting integration tests..."
    command="go test -v ./... -namespace ${NAMESPACE} -args -runIntegrationTests=true -isDevMode=true -runPostgreSQLTests=true"
    echo $command "$@"
    $command "$@"
else 
    echo "Starting MySQL DB port forwarding..."
    kubectl -n "$NAMESPACE" port-forward svc/mysql 3306:3306 --address=localhost & PORT_FORWARD_PID=$!
    # wait for kubectl port forward
    sleep 10
    echo "Starting integration tests..."
    command="go test -v ./... -namespace ${NAMESPACE} -args -runIntegrationTests=true -isDevMode=true"
    echo $command "$@"
    $command "$@"
fi
