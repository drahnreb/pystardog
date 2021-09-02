#!/bin/bash

function wait_for_start {
    (
    HOST=${1}
    STANDBY=${2}
    PORT=${3}
    # Wait for stardog to be running
    COUNT=0
    set +e
    while :
    do
      if [[ ${COUNT} -gt 50 ]]; then
          echo "Failed to start Stardog cluster on time"
          return 1;
      fi
      COUNT=$(expr 1 + ${COUNT} )
      sleep 5

      # wait for main cluster to be ready
      number_of_nodes=$(curl -s http://${HOST}:${PORT}/admin/cluster/ -u admin:admin | jq .'nodes | length')
      echo "number of nodes ready: " $number_of_nodes

      # wait for standby node to be ready. standby nodes needs to wait for main cluster first.
      curl -s http://${STANDBY}:5820/admin/healthcheck
      RC=$?
      if [[ $number_of_nodes -eq 2 && $RC -eq 0 ]]; then break; fi


    done
    # Give it a second to finish starting up.
    sleep 5

    return 0
    )
}

wait_for_start sdlb pystardog_standby_node 5820

pytest --endpoint http://sdlb:5820 -s
