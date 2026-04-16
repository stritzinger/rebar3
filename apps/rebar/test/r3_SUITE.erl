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

-module(r3_SUITE).

-export([all/0, init_per_testcase/2, end_per_testcase/2]).
-export([do_forms_run/1,
         async_do_forms_run/1,
         undefined_function_forms_run/1,
         break_without_async_returns_ok/1,
         resume_notifies_breakpoint_handler/1]).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

all() ->
    [do_forms_run,
     async_do_forms_run,
     undefined_function_forms_run,
     break_without_async_returns_ok,
     resume_notifies_breakpoint_handler].

init_per_testcase(_, Config) ->
    application:load(rebar),
    Config.

end_per_testcase(_, Config) ->
    case whereis(rebar_agent) of
        undefined ->
            ok;
        _Pid ->
            catch gen_server:stop(rebar_agent)
    end,
    catch unregister(r3_breakpoint_handler),
    Config.

do_forms_run(_Config) ->
    start_agent(),
    ?assertEqual(ok, r3:do(version)),
    ?assertEqual(ok, r3:do(default, ["version"])),
    ?assertEqual(ok, r3:do(default, ["clean", "-a"])),
    ?assertEqual(ok, r3:do(default, help, ["version"])).

async_do_forms_run(_Config) ->
    start_agent(),
    ?assertEqual(ok, r3:async_do(version)),
    ?assertEqual(ok, r3:async_do(default, ["version"])),
    ?assertEqual(ok, r3:async_do(default, ["clean", "-a"])),
    ?assertEqual(ok, r3:async_do(default, help, ["version"])),
    timer:sleep(500),
    ?assertEqual(ok, r3:do(version)).

undefined_function_forms_run(_Config) ->
    start_agent(),
    ?assertEqual(ok, r3:version()),
    ?assertEqual(ok, r3:help(["version"])).

break_without_async_returns_ok(_Config) ->
    start_agent(),
    ?assertEqual(ok, r3:break()).

resume_notifies_breakpoint_handler(_Config) ->
    register(r3_breakpoint_handler, self()),
    ?assertEqual(ok, r3:resume()),
    receive
        resume ->
            ok
    after 2000 ->
        ct:fail(timeout_waiting_for_resume)
    end.

start_agent() ->
    start_agent(rebar:init_config()).

start_agent(State) ->
    case rebar_agent:start_link(State) of
        {ok, _Pid} ->
            ok;
        {error, {already_started, _Pid}} ->
            ok
    end.
