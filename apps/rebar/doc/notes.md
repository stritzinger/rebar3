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

# Rebar Release Notes

This document describes the changes made in Rebar starting with version 4.0.0.

## Rebar 4.0.0-rc2

### Improvements and New Features

- HTTPS certificate validation now uses the operating system certificate store
through `public_key:cacerts_get()` by default. The `ssl_cacerts_path` global
configuration can still be used to specify a PEM bundle.

  [PR-1]

- Rebar no longer depends on certifi, ssl\_verify\_fun, and Erlware Commons.

  [PR-1], [PR-3], [PR-6], [PR-7], [PR-9], [PR-14], [PR-17], [PR-18]

- Rebar now uses Erlang/OTP's argparse for command line parsing and does no 
longer depend on Getopt. 

  [PR-2], [PR-8], [PR-11], [PR-12], [PR-13]

- Plugin dependencies will be locked now in the "rebar.lock" file with locking and unlocking support similar to normal dependencies.

  [PR-22], [PR-23], [PR-25], [PR-26]

- Upgrade hex\_core to version 0.19.0.

  [PR-30]

- Show vulnerability warnings and security advisories.

  [PR-31]

### Changes

- Commands accepting multiple application or dependency names now accept
space-separated values in addition to comma-separated values. For example:

  ```text
  rebar unlock dep1 dep2
  ```

  [PR-8]


- Providers is now part of Rebar instead of a vendored dependency.

  [PR-10]

- The executable, generated wrappers, local-install paths, and other
user-visible artifacts have been renamed from `rebar3` to `rebar`. The experimental `r3` shell API has been renamed to `rb`.

  [PR-15]

### Deprecations

- Providers that do not implement the optional `cli/0` callback remain
supported through the legacy option format, but this support will be removed
in the future. See
[`PLUGIN-CLI-MIGRATION.md`](../../../HOWTO/PLUGIN-CLI-MIGRATION.md) for migration
guidance.

  [PR-2], [PR-13]

### Removals

- Passing command arguments as one shell-style string in the `rb` shell API
is no longer supported. Use `rb:do(clean, ["-p", "test"])` instead of `rb:do(clean, "-p test")`.

  [PR-13]

- To list available templates, use `rebar new help`. Passing no template to
`rebar new` is no longer supported.

  [PR-8]


[PR-1]: https://github.com/stritzinger/rebar3/pull/1
[PR-2]: https://github.com/stritzinger/rebar3/pull/2
[PR-3]: https://github.com/stritzinger/rebar3/pull/3
[PR-6]: https://github.com/stritzinger/rebar3/pull/6
[PR-7]: https://github.com/stritzinger/rebar3/pull/7
[PR-8]: https://github.com/stritzinger/rebar3/pull/8
[PR-9]: https://github.com/stritzinger/rebar3/pull/9
[PR-10]: https://github.com/stritzinger/rebar3/pull/10
[PR-11]: https://github.com/stritzinger/rebar3/pull/11
[PR-12]: https://github.com/stritzinger/rebar3/pull/12
[PR-13]: https://github.com/stritzinger/rebar3/pull/13
[PR-14]: https://github.com/stritzinger/rebar3/pull/14
[PR-15]: https://github.com/stritzinger/rebar3/pull/15
[PR-17]: https://github.com/stritzinger/rebar3/pull/17
[PR-18]: https://github.com/stritzinger/rebar3/pull/18
[PR-22]: https://github.com/stritzinger/rebar3/pull/22
[PR-23]: https://github.com/stritzinger/rebar3/pull/23
[PR-25]: https://github.com/stritzinger/rebar3/pull/25
[PR-26]: https://github.com/stritzinger/rebar3/pull/26
[PR-30]: https://github.com/stritzinger/rebar3/pull/30
[PR-31]: https://github.com/stritzinger/rebar3/pull/31
