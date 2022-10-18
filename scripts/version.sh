#!/bin/bash

# TODO implement script to print full component version
# Script can be called either from Makefile (see Makefile)
# or from shell, or by another script using the 'version' bash function.
#
# Component version template: <VERSION>_rev-<REVISION><DIRTY>
# Where:
#  VERSION - SemVer2.0 string in the format <MAJOR>.<MINOR>.<PATCH> from the VERSION file
#  REVISION - Git short SHA1 of the repo
#  DIRTY - version "dirty" suffix ="-dirty" if the current status of of the git repository is "dirty" (*)
#
#  (*) It is considered a "dirty" state if one of the following conditions are true:
#      - uncommitted changes
#      - untracked files
#      - commit not in 'main' branch

usage() {
    echo "usage: $(basename "$0") [-hv]"
    echo "Get component full version string."
    echo "  Version format: <major>.<minor>.<patch>_rev-<revision><dirty>"
    echo "  Where:"
    echo "    VERSION - SemVer2.0 string in the format <MAJOR>.<MINOR>.<PATCH> from the VERSION file"
    echo "    REVISION - Git short SHA1 of the repo"
    echo "    DIRTY - version \"dirty\" suffix =\"-dirty\" if the current status of of the git repository is \"dirty\" (*)"
    echo ""
    echo "    (*) It is considered a \"dirty\" state if one of the following conditions are true:"
    echo "     - uncommitted changes"
    echo "     - untracked files"
    echo "     - commit not in 'main' branch"
    echo ""
    echo "  options:"
    echo "      -h|--help - display this help."
    echo "      -v|--verbose - set verbosity"
    echo "      --semver-only - print only the semver2.0 part of the version string"
    echo "      --revision-only - print only the revision part of the version string"
    echo "      --dirty-only - print only the dirty suffix if the repo is dirty"
    echo "      --long-revision - use long revision SHA1 instead of the default which is short"
    echo ""
    exit 1
}
LONG_REV=false
SEMVER_ONLY=false
REV_ONLY=false
DIRTY_ONLY=false

_set_args() {
    while :
    do
        case "$1" in
            -v | --verbose ) 
                VERBOSE=true;
                shift;
                ;;
            --semver-only ) 
                SEMVER_ONLY=true
                shift;
                break
                ;;
            --revision-only ) 
                REV_ONLY=true
                shift;
                ;;
            --dirty-only ) 
                DIRTY_ONLY=true
                shift;
                break
                ;;
            --long-revision ) 
                LONG_REV=true;
                shift;
                ;;
            -h| --help ) 
                usage
                ;;
            * )
                shift;
                break
                ;;
        esac
    done
}


SOURCE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VERSION_FILE="${SOURCE_DIR}/../VERSION"
GIT_DIR="${SOURCE_DIR}/../.git"



semver() {
    version_from_file=$(cat ${VERSION_FILE})
    echo "${version_from_file}"
}

revision() {
    if [ $# > 0 ] && [ "$1" = "true" ]; then
        commit_sha=$(git --git-dir="${GIT_DIR}" rev-parse HEAD)
    else
        commit_sha=$(git --git-dir="${GIT_DIR}" rev-parse --short HEAD)
    fi
    echo "${commit_sha}"
}

dirty() {
    if output=$(git --git-dir="${GIT_DIR}" status --porcelain) && [ ! -z "$output" ]; then
        echo "-dirty"
    fi
}

version() {
    _set_args $@
    if [[ "${SEMVER_ONLY}" == "true" ]]; then
        echo "$(semver)"
    elif [[ "${REV_ONLY}" = "true" ]]; then
        echo "$(revision $LONG_REV)"
    elif [[ "${DIRTY_ONLY}" = "true" ]]; then
        echo "$(dirty)"
    else
        echo "$(semver)_rev-$(revision $LONG_REV)$(dirty)"
    fi    
}

version $@
