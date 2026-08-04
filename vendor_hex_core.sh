#!/bin/bash

# %CopyrightBegin%
#
# SPDX-License-Identifier: Apache-2.0
#
# SPDX-FileCopyrightText: Copyright 2015-2026 Rebar3 and its contributors
#
# SPDX-FileCopyrightText: Copyright 2026 Dipl. Phys. Peer Stritzinger GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# %CopyrightEnd%

set -e

if [[ -z "$1" ]]; then
  echo "Usage: vendor_hex_core.sh PATH_TO_HEX_CORE"
  exit 1
fi

REBAR_TOP=$(pwd)/apps/rebar
export REBAR_TOP
pushd "$1"
touch proto/* # force re-generation of protobuf elements
TARGET_ERLANG_VERSION=26
export TARGET_ERLANG_VERSION
rebar as dev compile
./vendor.sh "$REBAR_TOP/src/vendored" rb_
popd
