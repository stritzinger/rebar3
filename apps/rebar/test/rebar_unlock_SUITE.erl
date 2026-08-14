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

-module(rebar_unlock_SUITE).
-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").
-compile(export_all).

all() -> [pkgunlock, unlock, unlock_space_args, unlock_all, unlock_no_args,
          checkout_plugins_are_not_locked,
          unlock_all_with_plugins, plugin_unlock].

init_per_testcase(unlock_all_with_plugins, Config0) ->
    Config = rebar_test_utils:init_rebar_state(Config0, "unlock"),
    Lockfile = filename:join(?config(apps, Config), "rebar.lock"),
    Deps = [{<<"ordinary">>, {git, "ordinary", {ref, "ordinary"}}, 0}],
    Plugins = [{<<"plugin1">>, {git, "plugin1", {ref, "plugin1"}}, 0}],
    ok = rebar_config:write_lock_file(Lockfile, [{deps, Deps}, {plugins, Plugins}]),
    [{lockfile, Lockfile} | Config];

init_per_testcase(plugin_unlock, Config0) ->
    Config = rebar_test_utils:init_rebar_state(Config0, "unlock"),
    Lockfile = filename:join(?config(apps, Config), "rebar.lock"),
    Deps = [{<<"ordinary">>, {git, "ordinary", {ref, "ordinary"}}, 0}],
    Plugins = [{<<"plugin1">>, {git, "plugin1", {ref, "plugin1"}}, 0},
               {<<"plugin2">>, {git, "plugin2", {ref, "plugin2"}}, 0}],
    ok = rebar_config:write_lock_file(Lockfile, [{deps, Deps}, {plugins, Plugins}]),
    [{lockfile, Lockfile} | Config];

init_per_testcase(pkgunlock, Config0) ->
    Config = rebar_test_utils:init_rebar_state(Config0, "pkgunlock"),
    Lockfile = filename:join(?config(apps, Config), "rebar.lock"),
    rebar_file_utils:copy(filename:join(?config(data_dir, Config), "pkg.rebar.lock"),
                 Lockfile),
    [{lockfile, Lockfile} | Config];
init_per_testcase(Case, Config0) ->
    Config = rebar_test_utils:init_rebar_state(Config0, atom_to_list(Case)),
    Lockfile = filename:join(?config(apps, Config), "rebar.lock"),
    rebar_file_utils:copy(filename:join(?config(data_dir, Config), "rebar.lock"),
                 Lockfile),
    [{lockfile, Lockfile} | Config].

end_per_testcase(_, Config) ->
    Config.

pkgunlock(Config) ->
    Locks = read_locks(Config),
    Hashes = read_hashes(Config),
    rebar_test_utils:run_and_check(Config, [], ["unlock", "fakeapp"], {ok, []}),
    Locks = read_locks(Config),
    Hashes = read_hashes(Config),
    rebar_test_utils:run_and_check(Config, [], ["unlock", "bbmustache"], {ok, []}),
    ?assertEqual(Locks -- ["bbmustache"], read_locks(Config)),
    ?assertEqual(Hashes -- ["bbmustache"], read_hashes(Config)),
    rebar_test_utils:run_and_check(Config, [], ["unlock", "cf,certifi"], {ok, []}),
    ?assertEqual(Locks -- ["bbmustache","cf","certifi"], read_locks(Config)),
    ?assertEqual(Hashes -- ["bbmustache","cf","certifi"], read_hashes(Config)),
    rebar_test_utils:run_and_check(Config, [], ["unlock", rebar_string:join(Locks,",")], {ok, []}),
    ?assertEqual({error, enoent}, read_locks(Config)),
    ?assertEqual({error, enoent}, read_hashes(Config)),
    ok.

unlock(Config) ->
    Locks = read_locks(Config),
    rebar_test_utils:run_and_check(Config, [], ["unlock", "fakeapp"], {ok, []}),
    Locks = read_locks(Config),
    {ok, State} = rebar_test_utils:run_and_check(Config, [], ["unlock", "uuid"], return),
    ?assertEqual(Locks -- ["uuid"], read_locks(Config)),
    ?assert(false =:= lists:keyfind(<<"uuid">>, 1, rebar_state:get(State, {locks, default}))),
    ?assert(false =/= lists:keyfind(<<"itc">>, 1, rebar_state:get(State, {locks, default}))),
    rebar_test_utils:run_and_check(Config, [], ["unlock", "gproc,itc"], {ok, []}),
    ?assertEqual(Locks -- ["uuid","gproc","itc"], read_locks(Config)),
    rebar_test_utils:run_and_check(Config, [], ["unlock", rebar_string:join(Locks,",")], {ok, []}),
    ?assertEqual({error, enoent}, read_locks(Config)),
    ok.

unlock_space_args(Config) ->
    Locks = read_locks(Config),
    rebar_test_utils:run_and_check(Config, [], ["unlock", "gproc", "itc"], {ok, []}),
    ?assertEqual(Locks -- ["gproc","itc"], read_locks(Config)),
    ok.

unlock_all(Config) ->
    [_|_] = read_locks(Config),
    {ok, State} = rebar_test_utils:run_and_check(Config, [], ["unlock", "--all"], return),
    ?assertEqual({error, enoent}, read_locks(Config)),
    ?assertEqual([], rebar_state:get(State, {locks, default})),
    ok.

unlock_all_with_plugins(Config) ->
    {ok, State} = rebar_test_utils:run_and_check(
        Config, [], ["unlock", "--all"], return),
    ?assert(filelib:is_regular(?config(lockfile, Config))),
    {[], Plugins} = rebar_config:consult_lock_file(?config(lockfile, Config)),
    ?assertEqual([<<"plugin1">>], [Name || {Name, _, _} <- Plugins]),
    ?assertEqual([], rebar_state:get(State, {locks, default})),
    ok.

unlock_no_args(Config) ->
    try rebar_test_utils:run_and_check(Config, [], ["unlock"], return)
    catch {error, {rebar_prv_unlock, no_arg}} ->
        ok
    end,
    ok.

checkout_plugins_are_not_locked(Config0) ->
    Config = rebar_test_utils:init_rebar_state(Config0, "checkout_plugins_"),
    AppDir = ?config(apps, Config),
    CheckoutsDir = ?config(checkouts, Config),
    AppName = rebar_test_utils:create_random_name("app1_"),
    PluginName = rebar_test_utils:create_random_name("plugin1_"),
    PluginDepName = rebar_test_utils:create_random_name("plugindep1_"),
    Vsn = "1.0.0",
    rebar_test_utils:create_app(AppDir, AppName, Vsn, [kernel, stdlib]),
    rebar_test_utils:create_plugin(
      filename:join(CheckoutsDir, PluginDepName), PluginDepName, Vsn, []),
    rebar_test_utils:create_plugin(
      filename:join(CheckoutsDir, PluginName), PluginName, Vsn, []),
    rebar_test_utils:create_config(
      filename:join(CheckoutsDir, PluginName),
      [{deps, [list_to_atom(PluginDepName)]}]),
    RConfFile = rebar_test_utils:create_config(
                  AppDir, [{plugins, [list_to_atom(PluginName)]}]),
    {ok, RConf} = file:consult(RConfFile),
    {ok, _} = rebar_test_utils:run_and_check(
                Config, RConf, ["lock"], return),
    LockFile = filename:join(AppDir, "rebar.lock"),
    {[], []} = rebar_config:consult_lock_file(LockFile),
    {ok, _} = rebar_test_utils:run_and_check(
                Config, RConf, ["unlock", PluginName], return),
    ?assertEqual({error, enoent}, file:consult(LockFile)),
    ok.

plugin_unlock(Config) ->
    {ok, State} = rebar_test_utils:run_and_check(
        Config, [], ["plugins", "unlock", "plugin1"], return),
    {Deps, Plugins} = rebar_config:consult_lock_file(?config(lockfile, Config)),
    ?assertEqual([{"ordinary", {git, "ordinary", {ref, "ordinary"}}, 0}],
                 [{binary_to_list(Name), Source, Level} ||
                     {Name, Source, Level} <- Deps]),
    ?assertEqual(false, lists:keyfind(<<"plugin1">>, 1, Plugins)),
    ?assert(lists:keyfind(<<"plugin2">>, 1, Plugins) =/= false),
    ?assertEqual([], rebar_state:get(State, {plugin_locks, default}) -- Plugins),
    rebar_test_utils:run_and_check(Config, [], ["plugins", "unlock", "--all"],
                                   {ok, []}),
    {Deps, []} = rebar_config:consult_lock_file(?config(lockfile, Config)),
    ok.

read_locks(Config) ->
    case file:consult(?config(lockfile, Config)) of
        {ok, _} ->
            {Locks, _} = rebar_config:consult_lock_file(?config(lockfile, Config)),
            [binary_to_list(element(1,Lock)) || Lock <- Locks];
        Other ->
            Other
    end.

read_hashes(Config) ->
    case file:consult(?config(lockfile, Config)) of
        {ok, [{_Vsn, _Locks},Props|_]} ->
            HashGroups = proplists:get_value(pkg_hash, Props, []),
            Hashes = case HashGroups of
                         [{deps, _}|_] ->
                             lists:append([Values || {_, Values} <- HashGroups]);
                         _ ->
                             HashGroups
                     end,
            [binary_to_list(element(1,Hash)) || Hash <- Hashes];
        {ok, [{_Vsn, _Locks}]} ->
            [];
        Other ->
            Other
    end.
