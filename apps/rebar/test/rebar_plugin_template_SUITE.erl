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

%% Built-in plugin template coverage:
%% generate a plugin, verify the scaffold shape, compile it, then run it.
-module(rebar_plugin_template_SUITE).
-compile(export_all).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").
-include_lib("kernel/include/file.hrl").

all() ->
    [generated_plugin_compiles,
     generated_plugin_runs_as_local_umbrella_plugin].

init_per_testcase(_, Config) ->
    rebar_test_utils:init_rebar_state(Config).

end_per_testcase(_, Config) ->
    Config.

generated_plugin_compiles(Config) ->
    BaseDir = ?config(apps, Config),
    PluginBaseDir = filename:join(BaseDir, "generated_plugins"),
    PluginName = rebar_test_utils:create_random_name("plugin_"),
    {PluginDir, ProviderFile, PluginBeam} =
        generate_plugin(PluginBaseDir, PluginName),

    assert_file_contains(ProviderFile,
                         ["-behaviour(provider).",
                          "-export([init/1, cli/0, do/1, format_error/1]).",
                          "-spec cli() -> argparse:command()."]),

    ?assertMatch({ok, _}, run_in_dir(PluginDir, fun() ->
        rebar3:run(["compile"])
    end)),
    ?assertMatch({ok, #file_info{}}, file:read_file_info(PluginBeam)).

generated_plugin_runs_as_local_umbrella_plugin(Config) ->
    UmbrellaDir = ?config(apps, Config),
    PluginBaseDir = filename:join(UmbrellaDir, "plugins"),
    PluginName = rebar_test_utils:create_random_name("plugin_"),
    AppName = rebar_test_utils:create_random_name("app_"),
    AppDir = filename:join([UmbrellaDir, "apps", AppName]),
    Vsn = rebar_test_utils:create_random_vsn(),
    {_PluginDir, _ProviderFile, _PluginBeam} =
        generate_plugin(PluginBaseDir, PluginName),

    rebar_test_utils:create_app(AppDir, AppName, Vsn, [kernel, stdlib]),
    RConfFile = rebar_test_utils:create_config(UmbrellaDir,
                                               [{plugins, [list_to_atom(PluginName)]}]),
    {ok, RConf} = file:consult(RConfFile),

    ?assertMatch({ok, _},
                 rebar_test_utils:run_and_check(
                   Config, RConf, [PluginName], {ok, []}
                 )).

generate_plugin(PluginBaseDir, PluginName) ->
    PluginDir = filename:join(PluginBaseDir, PluginName),
    ProviderFile = filename:join([PluginDir, "src", PluginName ++ "_prv.erl"]),
    PluginBeam = filename:join([PluginDir, "_build", "default", "lib",
                                PluginName, "ebin", PluginName ++ ".beam"]),
    ok = filelib:ensure_path(filename:join(PluginBaseDir, "dummy")),
    ?assertMatch({ok, _}, run_in_dir(PluginBaseDir, fun() ->
        rebar3:run(["new", "plugin", PluginName])
    end)),
    {PluginDir, ProviderFile, PluginBeam}.

run_in_dir(Dir, Fun) ->
    {ok, Cwd} = file:get_cwd(),
    try
        ok = file:set_cwd(Dir),
        Fun()
    after
        ok = file:set_cwd(Cwd)
    end.

assert_file_contains(Path, Patterns) ->
    {ok, Bin} = file:read_file(Path),
    [begin
         {Pos, _Len} = binary:match(Bin, unicode:characters_to_binary(Pattern)),
         ?assert(is_integer(Pos))
     end || Pattern <- Patterns],
    ok.
