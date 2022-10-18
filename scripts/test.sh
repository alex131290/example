#!/bin/bash

# TODO implement script to test component is running and its version is valid using its '/health' endpoint.
# Script can be called either from Makefile (see Makefile)
# or from shell, or by another script using the 'test' bash function.
#
# Component health endpoint: /health
#  Example output:
#    > curl localhost:8080/health
#    {"status":"OK", "version":"0.1.0_rev-8fd1adf"}
#
# See scripts/version.sh for version info and examples.
#
# Test should pass if service health is OK and its version is valid and not dirty
#

usage() {
    echo "usage: $(basename "$0") [-hv]"
    echo "Test component health and version."
    echo "The test should pass if the service health is OK and its version is valid and not dirty."
    echo ""
    echo "  options:"
    echo "      -h|--help - display this help."
    echo "      -v|--verbose - set verbosity"
    echo "      --expected-version - expected version, optional. Default is the current version."
    echo "      --service-image - The image to test, mandatory"
    echo ""
}

VERBOSE=false
TEST_STATUS="fail"

_set_args() {
    while :
    do
        case "$1" in
            -v | --verbose ) 
                VERBOSE=true;
                shift;
                ;;
            --expected-version ) 
                EXPECTED_VERSION="$2"
                shift 2;
                ;;
            --service-image ) 
                SERVICE_IMAGE="$2"
                shift 2;
                ;;
            -h| --help ) 
                usage
                exit 0
                ;;
            * )
                shift;
                break
                ;;
        esac
    done
}

test() {
    _set_args $@
    if [ -z "$SERVICE_IMAGE" ]; then
        usage
        exit 1
    fi
    echo "SERVICE_IMAGE=$SERVICE_IMAGE"
    EXAMPLE_IMG="$SERVICE_IMAGE" docker-compose up -d
    health_out=$(curl -s http://localhost:8080/health)
    version=$(echo "$health_out" | grep -o '"version":"[^"]*' | grep -o '[^"]*$')
    status=$(echo "$health_out" | grep -o '"status":"[^"]*' | grep -o '[^"]*$')
    echo "version is $version status is $status"
    echo "health_out=$health_out"
    if [ "$status" == "OK" ] && [[ ${version} != *"dirty"* ]]; then
        echo "Service is healthy"
        TEST_STATUS="pass"
    else
        echo "Service is unhealthy"
    fi
    docker-compose down
    if [[ "$TEST_STATUS" == "fail" ]]; then
        exit 1
    fi
}

test $@
