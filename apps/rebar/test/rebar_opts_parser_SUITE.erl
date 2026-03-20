%% %CopyrightBegin%
%%
%% SPDX-License-Identifier: Apache-2.0
%%
%% SPDX-FileCopyrightText: Copyright 2015-2026 Rebar3 and its contributors
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

-module(rebar_opts_parser_SUITE).

-export([all/0, init_per_testcase/2]).
-export([bad_arg_to_flag/1, missing_arg_to_flag/1]).

-include_lib("common_test/include/ct.hrl").


all() -> [bad_arg_to_flag, missing_arg_to_flag].

init_per_testcase(_, Config) ->
    rebar_test_utils:init_rebar_state(Config, "opts_parser_").

bad_arg_to_flag(Config) ->
    AppDir = ?config(apps, Config),

    Name = rebar_test_utils:create_random_name("bad_arg_"),
    Vsn = rebar_test_utils:create_random_vsn(),
    rebar_test_utils:create_app(AppDir, Name, Vsn, [kernel, stdlib]),

    {error, Error} = rebar_test_utils:run_and_check(Config,
                                                    [],
                                                    ["compile", "--foo=null"],
                                                    return),

    "erl: unknown argument: --foo=null" = lists:flatten(Error).

missing_arg_to_flag(Config) ->
    AppDir = ?config(apps, Config),

    Name = rebar_test_utils:create_random_name("missing_arg_"),
    Vsn = rebar_test_utils:create_random_vsn(),
    rebar_test_utils:create_app(AppDir, Name, Vsn, [kernel, stdlib]),

    {error, Error} = rebar_test_utils:run_and_check(Config,
                                                    [],
                                                    ["compile", "--foo"],
                                                    return),

    "erl: unknown argument: --foo" = lists:flatten(Error).
