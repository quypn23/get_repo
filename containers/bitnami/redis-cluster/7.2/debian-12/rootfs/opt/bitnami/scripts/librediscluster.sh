#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0
#
# redis Redis Cluster library

# shellcheck disable=SC1090,SC1091

# Load Generic Libraries
. /opt/redis/scripts/libfile.sh
. /opt/redis/scripts/libfs.sh
. /opt/redis/scripts/liblog.sh
. /opt/redis/scripts/libnet.sh
. /opt/redis/scripts/libos.sh
. /opt/redis/scripts/libservice.sh
. /opt/redis/scripts/libvalidations.sh
. /opt/redis/scripts/libredis.sh

# Functions

########################
# Validate settings in redis_* env vars.
# Globals:
#   redis_*
# Arguments:
#   None
# Returns:
#   None
#########################
redis_cluster_validate() {
    debug "Validating settings in redis_* env vars.."
    local error_code=0

    # Auxiliary functions
    print_validation_error() {
        error "$1"
        error_code=1
    }

    empty_password_enabled_warn() {
        warn "You set the environment variable ALLOW_EMPTY_PASSWORD=${ALLOW_EMPTY_PASSWORD}. For safety reasons, do not use this flag in a production environment."
    }
    empty_password_error() {
        print_validation_error "The $1 environment variable is empty or not set. Set the environment variable ALLOW_EMPTY_PASSWORD=yes to allow the container to be started with blank passwords. This is recommended only for development."
    }

    if is_boolean_yes "$ALLOW_EMPTY_PASSWORD"; then
        empty_password_enabled_warn
    else
        [[ -z "$redis_PASSWORD" ]] && empty_password_error redis_PASSWORD
    fi

    if ! is_boolean_yes "$redis_CLUSTER_DYNAMIC_IPS"; then
        [[ -z "$redis_CLUSTER_ANNOUNCE_IP" ]] && print_validation_error "To provide external access you need to provide the redis_CLUSTER_ANNOUNCE_IP env var"
    fi

    [[ -z "$redis_NODES" ]] && print_validation_error "redis_NODES is required"

    if [[ -z "$redis_PORT_NUMBER" ]]; then
        print_validation_error "redis_PORT_NUMBER cannot be empty"
    fi

    if is_boolean_yes "$redis_CLUSTER_CREATOR"; then
        [[ -z "$redis_CLUSTER_REPLICAS" ]] && print_validation_error "To create the cluster you need to provide the number of replicas to the cluster creator"
    fi

    if ((redis_CLUSTER_SLEEP_BEFORE_DNS_LOOKUP < 0)); then
        print_validation_error "redis_CLUSTER_SLEEP_BEFORE_DNS_LOOKUP must be greater or equal to zero"
    fi

    [[ "$error_code" -eq 0 ]] || exit "$error_code"
}

########################
# Redis specific configuration to override the default one
# Globals:
#   redis_*
# Arguments:
#   None
# Returns:
#   None
#########################
redis_cluster_override_conf() {
    # Redis configuration to override
    if ! is_boolean_yes "$redis_CLUSTER_DYNAMIC_IPS"; then
        redis_conf_set cluster-announce-ip "$redis_CLUSTER_ANNOUNCE_IP"
    fi
    if is_boolean_yes "$redis_CLUSTER_DYNAMIC_IPS"; then
        # Always set the announce-ip to avoid issues when using proxies and traffic restrictions.
        redis_conf_set cluster-announce-ip "$(get_machine_ip)"
    fi
    if ! is_empty_value "$redis_CLUSTER_ANNOUNCE_HOSTNAME"; then
        redis_conf_set "cluster-announce-hostname" "$redis_CLUSTER_ANNOUNCE_HOSTNAME"
    fi
    if ! is_empty_value "$redis_CLUSTER_PREFERRED_ENDPOINT_TYPE"; then
        redis_conf_set "cluster-preferred-endpoint-type" "$redis_CLUSTER_PREFERRED_ENDPOINT_TYPE"
    fi
    if is_boolean_yes "$redis_TLS_ENABLED"; then
        redis_conf_set tls-cluster yes
        redis_conf_set tls-replication yes
    fi
    if ! is_empty_value "$redis_CLUSTER_ANNOUNCE_PORT"; then
        redis_conf_set "cluster-announce-port" "$redis_CLUSTER_ANNOUNCE_PORT"
    fi
    if ! is_empty_value "$redis_CLUSTER_ANNOUNCE_BUS_PORT"; then
        redis_conf_set "cluster-announce-bus-port" "$redis_CLUSTER_ANNOUNCE_BUS_PORT"
    fi
    # Multithreading configuration
    if ! is_empty_value "$redis_IO_THREADS_DO_READS"; then
        redis_conf_set "io-threads-do-reads" "$redis_IO_THREADS_DO_READS"
    fi
    if ! is_empty_value "$redis_IO_THREADS"; then
        redis_conf_set "io-threads" "$redis_IO_THREADS"
    fi
}

########################
# Ensure Redis is initialized
# Globals:
#   redis_*
# Arguments:
#   None
# Returns:
#   None
#########################
redis_cluster_initialize() {
    redis_configure_default
    redis_cluster_override_conf
}

########################
# Creates the Redis cluster
# Globals:
#   redis_*
# Arguments:
#   - $@ Array with the hostnames
# Returns:
#   None
#########################
redis_cluster_create() {
    local nodes=("$@")
    local sockets=()
    local wait_command
    local create_command

    for node in "${nodes[@]}"; do
        read -r -a host_and_port <<< "$(to_host_and_port "$node")"
        wait_command="timeout 5 redis-cli -h ${host_and_port[0]} -p ${host_and_port[1]} ping"
        if is_boolean_yes "$redis_TLS_ENABLED"; then
            wait_command="${wait_command:0:-5} --tls --cert ${redis_TLS_CERT_FILE} --key ${redis_TLS_KEY_FILE} --cacert ${redis_TLS_CA_FILE} ping"
        fi
        while [[ $($wait_command) != 'PONG' ]]; do
            echo "Node $node not ready, waiting for all the nodes to be ready..."
            sleep 1
        done
    done

    echo "Waiting ${redis_CLUSTER_SLEEP_BEFORE_DNS_LOOKUP}s before querying node ip addresses"
    sleep "${redis_CLUSTER_SLEEP_BEFORE_DNS_LOOKUP}"

    for node in "${nodes[@]}"; do
        read -r -a host_and_port <<< "$(to_host_and_port "$node")"
        sockets+=("$(wait_for_dns_lookup "${host_and_port[0]}" "${redis_CLUSTER_DNS_LOOKUP_RETRIES}" "${redis_CLUSTER_DNS_LOOKUP_SLEEP}"):${host_and_port[1]}")
    done

    create_command="redis-cli --cluster create ${sockets[*]} --cluster-replicas ${redis_CLUSTER_REPLICAS} --cluster-yes"
    if is_boolean_yes "$redis_TLS_ENABLED"; then
        create_command="${create_command} --tls --cert ${redis_TLS_CERT_FILE} --key ${redis_TLS_KEY_FILE} --cacert ${redis_TLS_CA_FILE}"
    fi
    yes yes | $create_command || true
    if redis_cluster_check "${sockets[0]}"; then
        echo "Cluster correctly created"
    else
        echo "The cluster was already created, the nodes should have recovered it"
    fi
}

#########################
## Checks if the cluster state is correct.
## Params:
##  - $1: node where to check the cluster state
#########################
redis_cluster_check() {
    if is_boolean_yes "$redis_TLS_ENABLED"; then
        local -r check=$(redis-cli --tls --cert "${redis_TLS_CERT_FILE}" --key "${redis_TLS_KEY_FILE}" --cacert "${redis_TLS_CA_FILE}" --cluster check "$1")
    else
        local -r check=$(redis-cli --cluster check "$1")
    fi
    if [[ $check =~ "All 16384 slots covered" ]]; then
        true
    else
        false
    fi
}

#########################
## Recovers the cluster when using dynamic IPs by changing them in the nodes.conf
# Globals:
#   redis_*
# Arguments:
#   None
# Returns:
#   None
#########################
redis_cluster_update_ips() {
    read -ra nodes <<< "$(tr ',;' ' ' <<< "${redis_NODES}")"
    declare -A host_2_ip_array # Array to map hosts and IPs
    # Update the IPs when a number of nodes > quorum change their IPs
    if [[ ! -f "${redis_DATA_DIR}/nodes.sh" || ! -f "${redis_DATA_DIR}/nodes.conf" ]]; then
        # It is the first initialization so store the nodes
        for node in "${nodes[@]}"; do
            read -r -a host_and_port <<< "$(to_host_and_port "$node")"
            ip=$(wait_for_dns_lookup "${host_and_port[0]}" "$redis_DNS_RETRIES" 5)
            host_2_ip_array["$node"]="$ip"
        done
        echo "Storing map with hostnames and IPs"
        declare -p host_2_ip_array >"${redis_DATA_DIR}/nodes.sh"
    else
        # The cluster was already started
        . "${redis_DATA_DIR}/nodes.sh"
        # Update the IPs in the nodes.conf
        for node in "${nodes[@]}"; do
            read -r -a host_and_port <<< "$(to_host_and_port "$node")"
            newIP=$(wait_for_dns_lookup "${host_and_port[0]}" "$redis_DNS_RETRIES" 5)
            # The node can be new if we are updating the cluster, so catch the unbound variable error
            if [[ ${host_2_ip_array[$node]+true} ]]; then
                info "Changing old IP ${host_2_ip_array[$node]} by the new one ${newIP}"
                nodesFile=$(sed "s/ ${host_2_ip_array[$node]}:/ $newIP<NEWIP>:/g" "${redis_DATA_DIR}/nodes.conf")
                echo "$nodesFile" >"${redis_DATA_DIR}/nodes.conf"
            fi
            host_2_ip_array["$node"]="$newIP"
        done
        replace_in_file "${redis_DATA_DIR}/nodes.conf" "<NEWIP>:" ":" false
        declare -p host_2_ip_array >"${redis_DATA_DIR}/nodes.sh"
    fi
}

#########################
## Assigns a port to the host if one is not set using redis defaults
# Globals:
#   redis_*
# Arguments:
#   $1 - redis host or redis host and port
# Returns:
#   - 2 element Array of host and port
#########################
to_host_and_port() {
    local host="${1:?host is required}"
    read -r -a host_and_port <<< "$(echo "$host" | tr ":" " ")"

    if [ "${#host_and_port[*]}" -eq "1" ]; then
        if is_boolean_yes "$redis_TLS_ENABLED"; then
            host_and_port=("${host_and_port[0]}" "${redis_TLS_PORT_NUMBER}")
        else
            host_and_port=("${host_and_port[0]}" "${redis_PORT_NUMBER}")
        fi
    fi

    echo "${host_and_port[*]}"
}
