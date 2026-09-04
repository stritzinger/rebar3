<!--
%%
%% %CopyrightBegin%
%%
%% SPDX-License-Identifier: Apache-2.0
%%
%% SPDX-FileCopyrightText: Copyright 2026 Dipl. Phys. Peer Stritzinger GmbH
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% %CopyrightEnd%
-->

# Provider Release Notes

This document describes the changes made in the Providers library starting with
version 2.0.0.

## Providers 2.0.0

### Changes

- Providers has been fully integrated in Rebar and will no longer be a vendored
dependency.

  [PR-10]

- Providers no longer depends on Getopt or Erlware Commons.

  [PR-12], [PR-13]

- Command line parsing has been moved to Rebar and Providers behaviour supports
an optional `cli/0` callback function returning an `argparse:command()`
specification.

  [PR-13]

### Deprecations

- Not implementing `cli/0` callback in a provider is still supported, but the 
support will be removed in the future.
See [`PLUGIN-CLI-MIGRATION.md`](../../../HOWTO/PLUGIN-CLI-MIGRATION.md) for migration
guidance.

  [PR-13]

### Removals

- The old Providers help API has been removed. Help text are generated from the
new `cli/0` callback function and are likely not working for legacy providers.

  [PR-12]


[PR-10]: https://github.com/stritzinger/rebar3/pull/10
[PR-12]: https://github.com/stritzinger/rebar3/pull/12
[PR-13]: https://github.com/stritzinger/rebar3/pull/13
