%% SPDX-License-Identifier: Apache-2.0
%% SPDX-FileCopyrightText: 2026 Dipl. Phys. Peer Stritzinger GmbH

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
    start_agent(rebar3:init_config()).

start_agent(State) ->
    case rebar_agent:start_link(State) of
        {ok, _Pid} ->
            ok;
        {error, {already_started, _Pid}} ->
            ok
    end.
