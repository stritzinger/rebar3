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

# https://docs.docker.com/engine/reference/builder/#from
#   "The FROM instruction initializes a new build stage and sets the
#    Base Image for subsequent instructions."
FROM erlang:20.3.8.1-alpine as builder
# https://docs.docker.com/engine/reference/builder/#label
#   "The LABEL instruction adds metadata to an image."
LABEL stage=builder

# Install git for fetching non-hex dependencies. Also allows rebar
# to find it's own git version.
# Add any other Alpine libraries needed to compile the project here.
# See https://wiki.alpinelinux.org/wiki/Local_APK_cache for details
# on the local cache and need for the symlink
RUN ln -s /var/cache/apk /etc/apk/cache && \
    apk update && \
    apk add --update openssh-client git

# WORKDIR is located in the image
#   https://docs.docker.com/engine/reference/builder/#workdir
WORKDIR /root/rebar

# copy the entire src over and build
COPY . .
RUN ./bootstrap

# this is the final runner layer, notice how it diverges from the original erlang
# alpine layer, this means this layer won't have any of the other stuff that was
# generated previously (deps, build, etc)
FROM erlang:20.3.8.1-alpine as runner

# copy the generated `rebar` binary over here
COPY --from=builder /root/rebar/_build/prod/bin/rebar .

# and install it
RUN HOME=/opt ./rebar local install \
    && rm -f /usr/local/bin/rebar \
    && ln /opt/.cache/rebar/bin/rebar /usr/local/bin/rebar \
    && rm -rf rebar

# simply print out the version for visibility
ENTRYPOINT ["/usr/local/bin/rebar"]
CMD ["--version"]
