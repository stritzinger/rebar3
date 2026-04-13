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

# Rebar 4 Migration Notes

This document collects user-facing changes that are relevant when migrating
tooling, plugins, and shell workflows to rebar `4.x`.

## Plugin CLI migration

For plugin provider CLI migration, see [PLUGIN-CLI-MIGRATION.md](PLUGIN-CLI-MIGRATION.md).

### Template listing

The `new` provider allows to create projects using templates.

#### Change

To list available templates, use `rebar new help`.

Passing no template to `rebar new` is no longer the way to list templates.

### Space-separated dependency and app arguments

For commands that accept multiple dependency or app names `rebar` now supports space-separated values.

Examples:

- `rebar3 clean --apps app1 app2`
- `rebar3 unlock dep1 dep2`
- `rebar3 upgrade dep1 dep2`

Comma-separated values are still accepted for backwards compatibility.

### Experimental `r3` module shell API

The `r3` module is the shell-facing convenience wrapper around `rebar_agent`
that is available from `rebar3 shell`.

#### Change

Passing command arguments as one shell-style string is no longer supported.

Unsupported examples:

- `r3:do(clean, "-p test")`
- `r3:async_do(clean, "-p test")`

Use argv-style lists instead:

- `r3:do(clean, ["-p", "test"])`
- `r3:async_do(clean, ["-p", "test"])`
- `r3:do(default, clean, ["-p", "test"])`
- `r3:async_do(default, clean, ["-p", "test"])`

Still supported as before:

- `r3:do(Command)`
- `r3:do(Namespace, Command)`
- the corresponding `r3:async_do(...)` forms
- shortcuts such as `r3:version()` and `r3:help(["version"])`
