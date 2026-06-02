#!/bin/bash
set -e

if [[ -z "$1" ]]; then
  echo "Usage: vendor_hex_core.sh PATH_TO_HEX_CORE"
  exit 1
fi

REBAR_TOP=$(pwd)/apps/rebar
export REBAR_TOP
pushd "$1"
touch proto/* # force re-generation of protobuf elements
TARGET_ERLANG_VERSION=25
export TARGET_ERLANG_VERSION
rebar as dev compile
./vendor.sh src r3_
find src -regex '.*r3_.*' -exec mv -f {} "$REBAR_TOP/src/vendored" \;
popd
