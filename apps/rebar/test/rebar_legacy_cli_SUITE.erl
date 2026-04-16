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

-module(rebar_legacy_cli_SUITE).
-compile(export_all).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

all() ->
    [help_nonbare_found,
     help_with_legacy_string_provider_notfound,
     help_with_legacy_conflicting_short_provider_notfound,
     help_overview_with_legacy_conflicting_short_provider,
     global_help_with_legacy_reserved_short_is_valid,
     global_help_with_duplicate_shorts_in_different_providers_is_valid,
     to_command_argparse_drops_reserved_short_option,
     to_command_argparse_accepts_long_options_for_duplicate_short_options,
     to_command_argparse_keeps_typed_legacy_options_optional,
     to_command_argparse_keeps_legacy_positional_optional,
     to_command_argparse_matches_legacy_runtime_for_getopt_types,
     to_command_argparse_accepts_iodata_provider_help,
     legacy_runtime_accepts_reserved_global_short_options,
     legacy_runtime_keeps_positional_rest_for_subcommand_style_provider].

init_per_testcase(Case, Config0) ->
    Config = rebar_test_utils:init_rebar_state(Config0),
    AppDir = ?config(apps, Config),
    Name = rebar_test_utils:create_random_name("app1_" ++ atom_to_list(Case)),
    Vsn = rebar_test_utils:create_random_vsn(),
    rebar_test_utils:create_app(AppDir, Name, Vsn, [kernel, stdlib]),
    [{name, Name} | Config].

end_per_testcase(_, Config) ->
    Config.

help_nonbare_found(Config) ->
    Command = ["help", "nonbare_provider"],
    rebar_test_utils:run_and_check(
      add_nonbare_provider(Config), [], Command,
      {ok, []}
    ).

help_with_legacy_string_provider_notfound(Config) ->
    Command = ["help", "fakecommand"],
    rebar_test_utils:run_and_check(
      add_legacy_string_provider(Config), [], Command,
      {error, "Command fakecommand not found"}
    ).

help_with_legacy_conflicting_short_provider_notfound(Config) ->
    Command = ["help", "fakecommand"],
    rebar_test_utils:run_and_check(
      add_legacy_conflicting_short_provider(Config), [], Command,
      {error, "Command fakecommand not found"}
    ).

help_overview_with_legacy_conflicting_short_provider(Config) ->
    Command = ["help"],
    rebar_test_utils:run_and_check(
      add_legacy_conflicting_short_provider(Config), [], Command,
      {ok, []}
    ).

global_help_with_legacy_reserved_short_is_valid(Config) ->
    State = add_legacy_reserved_short_provider_state(?config(state, Config)),
    Cli = rebar_cli:global_cli(rebar_state:providers(State)),
    Help = argparse:help(Cli, #{progname => "rebar"}),
    ?assert(is_list(Help) orelse is_binary(Help)).

global_help_with_duplicate_shorts_in_different_providers_is_valid(Config) ->
    State0 = ?config(state, Config),
    State1 = rebar_state:add_provider(State0, duplicate_short_provider(one, "first")),
    State2 = rebar_state:add_provider(State1, duplicate_short_provider(two, "second")),
    Cli = rebar_cli:global_cli(rebar_state:providers(State2)),
    Overview = argparse:help(Cli, #{progname => "rebar"}),
    HelpOne = argparse:help(Cli, #{progname => "rebar", command => ["one"]}),
    HelpTwo = argparse:help(Cli, #{progname => "rebar", command => ["two"]}),
    {ok, Parsed1, Path1, _Cmd1} = argparse:parse(["one", "-k", "alpha"], Cli),
    {ok, Parsed2, Path2, _Cmd2} = argparse:parse(["two", "-k", "beta"], Cli),
    ?assert(is_list(Overview) orelse is_binary(Overview)),
    ?assert(is_list(HelpOne) orelse is_binary(HelpOne)),
    ?assert(is_list(HelpTwo) orelse is_binary(HelpTwo)),
    ?assertEqual(["erl", "one"], Path1),
    ?assertEqual(["erl", "two"], Path2),
    ?assertEqual("alpha", maps:get(value, Parsed1)),
    ?assertEqual("beta", maps:get(value, Parsed2)).

to_command_argparse_drops_reserved_short_option(_Config) ->
    Provider = reserved_short_and_long_provider(),
    Cli = rebar_legacy_cli:to_command(Provider),
    ?assertMatch({error, _}, argparse:parse(["-v", "1.2.3"], Cli)).

to_command_argparse_accepts_long_options_for_duplicate_short_options(_Config) ->
    Provider = duplicate_short_defaults_provider(),
    Cli = rebar_legacy_cli:to_command(Provider),
    {ok, ParsedMap, _Path, _Cmd} =
        argparse:parse(["--columns", "name,version", "--cached"], Cli),
    ?assertEqual("name,version", maps:get(columns, ParsedMap)),
    ?assertEqual(true, maps:get(cached, ParsedMap)).

to_command_argparse_keeps_typed_legacy_options_optional(_Config) ->
    Provider = getopt_types_legacy_provider(),
    Cli = rebar_legacy_cli:to_command(Provider),
    {ok, ParsedMap, _Path, _Cmd} = argparse:parse(["needle"], Cli),
    ?assertEqual("needle", maps:get(term, ParsedMap)),
    ?assertEqual(false, maps:is_key(string_opt, ParsedMap)),
    ?assertEqual(false, maps:is_key(block_size, ParsedMap)),
    ?assertEqual(1, maps:get(count, ParsedMap)).

to_command_argparse_keeps_legacy_positional_optional(_Config) ->
    Cli = rebar_legacy_cli:to_command(package_info_provider()),
    {ok, ParsedMap, _Path, _Cmd} = argparse:parse([], Cli),
    ?assertEqual(false, maps:is_key(package, ParsedMap)).

to_command_argparse_matches_legacy_runtime_for_getopt_types(Config) ->
    Provider = getopt_types_legacy_provider(),
    Args = ["needle",
            "-s", "out.txt",
            "--count", "3",
            "--ratio", "1.5",
            "--mode", "fast",
            "--blob", "bin-data",
            "--utf8", "utf8-data",
            "--block-size", "512",
            "--force"],
    {LegacyOpts, _} =
        parsed_opts_via_runtime(Config, Provider, getopt_types_legacy_provider, Args),
    Cli = rebar_legacy_cli:to_command(Provider),
    {ok, ParsedMap, _Path, _Cmd} = argparse:parse(Args, Cli),
    ?assertEqual("needle", proplists:get_value(term, LegacyOpts)),
    ?assertEqual("out.txt", proplists:get_value(string_opt, LegacyOpts)),
    ?assertEqual(3, proplists:get_value(count, LegacyOpts)),
    ?assertEqual(1.5, proplists:get_value(ratio, LegacyOpts)),
    ?assertEqual(fast, proplists:get_value(mode, LegacyOpts)),
    ?assertEqual("bin-data", proplists:get_value(blob, LegacyOpts)),
    ?assertEqual("utf8-data", proplists:get_value(utf8, LegacyOpts)),
    ?assertEqual(512, proplists:get_value(block_size, LegacyOpts)),
    ?assertEqual(true, proplists:get_value(force, LegacyOpts, false)),
    ?assertEqual(proplists:get_value(term, LegacyOpts), maps:get(term, ParsedMap)),
    ?assertEqual(proplists:get_value(string_opt, LegacyOpts), maps:get(string_opt, ParsedMap)),
    ?assertEqual(proplists:get_value(count, LegacyOpts), maps:get(count, ParsedMap)),
    ?assertEqual(proplists:get_value(ratio, LegacyOpts), maps:get(ratio, ParsedMap)),
    ?assertEqual(proplists:get_value(mode, LegacyOpts), maps:get(mode, ParsedMap)),
    ?assertEqual(proplists:get_value(blob, LegacyOpts), maps:get(blob, ParsedMap)),
    ?assertEqual(proplists:get_value(utf8, LegacyOpts), maps:get(utf8, ParsedMap)),
    ?assertEqual(proplists:get_value(block_size, LegacyOpts), maps:get(block_size, ParsedMap)),
    ?assertEqual(proplists:get_value(force, LegacyOpts, false), maps:get(force, ParsedMap)).

to_command_argparse_accepts_iodata_provider_help(_Config) ->
    Cli = rebar_legacy_cli:to_command(iodata_help_provider()),
    Help = argparse:help(Cli, #{progname => "rebar3 xref"}),
    ?assert(is_list(Help) orelse is_binary(Help)).

legacy_runtime_accepts_reserved_global_short_options(_Config) ->
    Provider = subcommand_style_legacy_provider(),
    Cli = rebar_legacy_cli:to_parse_command(Provider),
    {ok, HelpMap, _Path1, _Cmd1} =
        argparse:parse(["-h"], Cli),
    {ok, VersionMap, _Path2, _Cmd2} =
        argparse:parse(["-v"], Cli),
    ?assertEqual(true, maps:get(help, HelpMap, false)),
    ?assertEqual(true, maps:get(version, VersionMap, false)).

legacy_runtime_keeps_positional_rest_for_subcommand_style_provider(_Config) ->
    Provider = subcommand_style_legacy_provider(),
    Args = ["list", "pkg", "--level", "maintainer", "--transfer"],
    Cli = rebar_legacy_cli:to_parse_command(Provider),
    {ok, ParsedMap, _Path, _Cmd} =
        argparse:parse(Args, Cli),
    Opts = lists:keydelete(rest, 1, maps:to_list(ParsedMap)),
    Rest = maps:get(rest, ParsedMap, []),
    ?assertEqual("list", proplists:get_value(task, Opts)),
    ?assertEqual("maintainer", proplists:get_value(level, Opts)),
    ?assertEqual(true, proplists:get_value(transfer, Opts, false)),
    ?assertEqual(["pkg"], Rest).

%%% Helpers %%%

add_nonbare_provider(Config) ->
    State = ?config(state, Config),
    State1 = rebar_state:add_provider(
      State,
      providers:create(
        [{name, nonbare_provider},
         {module, ?MODULE},
         {namespace, default},
         {bare, false},
         {deps, []},
         {opts, []}]
       )
     ),
    [{state, State1} | Config].

add_legacy_string_provider(Config) ->
    State = ?config(state, Config),
    State1 = rebar_state:add_provider(
      State,
      providers:create(
        [{name, configure},
         {module, ?MODULE},
         {namespace, legacy},
         {bare, true},
         {deps, []},
         {opts, [{token, $t, "token", string, "Token"}]}]
       )
     ),
    [{state, State1} | Config].

add_legacy_conflicting_short_provider(Config) ->
    State = ?config(state, Config),
    State1 = rebar_state:add_provider(
      State,
      providers:create(
        [{name, configure},
         {module, ?MODULE},
         {namespace, legacy},
         {bare, true},
         {deps, []},
         {opts, [{psk, $p, "psk", string, "PSK"},
                 {ssid, $p, "ssid", string, "SSID"}]}]
       )
     ),
    [{state, State1} | Config].

add_legacy_reserved_short_provider_state(State) ->
    rebar_state:add_provider(
      State,
      providers:create(
        [{name, reserved_short_provider},
         {module, ?MODULE},
         {namespace, default},
         {bare, true},
         {deps, []},
         {opts, [{relvsn, $v, "relvsn", string, "Release version"}]}]
       )
     ).

parsed_opts_via_runtime(Config, Provider, Command, Args) ->
    {ok, State1} = rebar_test_utils:run_and_check(
      add_provider(Config, Provider), [], [atom_to_list(Command) | Args], return
    ),
    rebar_state:command_parsed_args(State1).

add_provider(Config, Provider) ->
    State = ?config(state, Config),
    State1 = rebar_state:add_provider(State, Provider),
    [{state, State1} | Config].

%% callback for fake providers used in this suite.
do(State) ->
    {ok, State}.

reserved_short_and_long_provider() ->
    providers:create(
      [{name, reserved_short_and_long_provider},
       {module, ?MODULE},
       {namespace, default},
       {bare, true},
       {deps, []},
       {opts, [{conflict, $v, "version", string, "Conflicting option"}]}]
     ).

getopt_types_legacy_provider() ->
    providers:create(
      [{name, getopt_types_legacy_provider},
       {module, ?MODULE},
       {namespace, default},
       {bare, true},
       {deps, []},
       {opts, [{term, undefined, undefined, string, "Search term"},
               {string_opt, $s, "string-opt", string, "String option"},
               {count, $c, "count", {integer, 1}, "Count"},
               {ratio, $r, "ratio", {float, 0.5}, "Ratio"},
               {mode, $m, "mode", atom, "Mode"},
               {blob, $b, "blob", binary, "Binary value"},
               {utf8, $u, "utf8", utf8_binary, "UTF-8 binary value"},
               {block_size, undefined, "block-size", integer, "Block size"},
               {force, $f, "force", {boolean, false}, "Force"}]}]
     ).

duplicate_short_defaults_provider() ->
    providers:create(
      [{name, duplicate_short_defaults_provider},
       {module, ?MODULE},
       {namespace, default},
       {bare, true},
       {deps, []},
       {opts, [{columns, $c, "columns", string, "List columns to display"},
               {type, $t, "type", {string, "otp"}, "Package type"},
               {cached, $c, "cached", {boolean, false}, "List only cached packages"}]}]
     ).

duplicate_short_provider(Name, Long) ->
    providers:create(
      [{name, Name},
       {module, ?MODULE},
       {namespace, default},
       {bare, true},
       {deps, []},
       {opts, [{value, $k, Long, string, "Duplicate short in another command"}]}]
     ).

iodata_help_provider() ->
    providers:create(
      [{name, iodata_help_provider},
       {module, rebar_prv_xref},
       {namespace, default},
       {bare, true},
       {deps, []},
       {opts, []}]
     ).

package_info_provider() ->
    providers:create(
      [{name, package_info_provider},
       {module, ?MODULE},
       {namespace, default},
       {bare, true},
       {deps, []},
       {opts, [{package, undefined, undefined, string,
                "Package to fetch information for."}]}]
     ).

subcommand_style_legacy_provider() ->
    providers:create(
      [{name, subcommand_style_legacy_provider},
       {module, ?MODULE},
       {namespace, default},
       {bare, true},
       {deps, []},
       {opts, [{level, $l, "level", {string, "full"}, "Ownership level"},
               {transfer, $t, "transfer", {boolean, false}, "Transfer package"}]}]
     ).
