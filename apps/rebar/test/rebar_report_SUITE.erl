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

-module(rebar_report_SUITE).

-compile(export_all).

-include_lib("stdlib/include/assert.hrl").

all() ->
    [report_with_task_succeeds].

init_per_testcase(_, Config) ->
    rebar_test_utils:init_rebar_state(Config).

report_with_task_succeeds(Config) ->
    ?assertMatch(
        {ok, _},
        rebar_test_utils:run_and_check(Config, [], ["report", "compile"], return)
    ).
