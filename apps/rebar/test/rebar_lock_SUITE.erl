%%% Most locking tests are implicit in other test suites handling
%%% dependencies.
%%% This suite is to test the compatibility layers between various
%%% versions of lockfiles.
-module(rebar_lock_SUITE).
-compile(export_all).
-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

all() -> [current_version, version_1_2, version_1_1,
          beta_version, future_versions_no_attrs, future_versions_attrs,
          empty_attrs_format, flat_locks_are_grouped,
          checkout_plugins_are_not_locked].

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
    ok.

empty_attrs_format(Config) ->
    LockFile = filename:join(?config(priv_dir, Config), "empty_attrs"),
    ok = rebar_config:write_lock_file(LockFile, [{deps, []}, {plugins, []}]),
    ?assertEqual({ok, <<"{\"2.0.0\",\n[{deps,[]},{plugins,[]}]}\.\n[].\n">>},
                 file:read_file(LockFile)).

current_version(Config) ->
    LockFile = filename:join(?config(priv_dir, Config), "current_version"),
    Deps = [{<<"dep1">>, {pkg, <<"dep1">>, <<"1.0.0">>,
                           <<"dep1-inner">>, <<"dep1-outer">>}, 0}],
    Plugins = [{<<"plugin1">>, {git, "https://example.org/plugin1.git",
                                {ref, "plugin-ref"}}, 0}],
    Locks = [{deps, Deps}, {plugins, Plugins}],
    ok = rebar_config:write_lock_file(LockFile, Locks),
    ?assertEqual({Deps, Plugins}, rebar_config:consult_lock_file(LockFile)),
    {ok, [{"2.0.0", Written}|Attrs]} = file:consult(LockFile),
    ?assertEqual([{deps, [{<<"dep1">>, {pkg, <<"dep1">>, <<"1.0.0">>}, 0}]},
                  {plugins, Plugins}], Written),
    ?assertEqual([[{pkg_hash, [{deps, [{<<"dep1">>, <<"dep1-inner">>}]},
                               {plugins, []}]},
                   {pkg_hash_ext, [{deps, [{<<"dep1">>, <<"dep1-outer">>}]},
                                   {plugins, []}]}]],
                 Attrs).

flat_locks_are_grouped(Config) ->
    LockFile = filename:join(?config(priv_dir, Config), "flat_locks"),
    Locks = [{<<"dep1">>, {pkg, <<"dep1">>, <<"1.0.0">>,
                             <<"old-hash">>, <<"new-hash">>}, 0}],
    ok = rebar_config:write_lock_file(LockFile, Locks),
    ?assertEqual({Locks, []}, rebar_config:consult_lock_file(LockFile)),
    {ok, [{"2.0.0", Written}, Attrs]} = file:consult(LockFile),
    ?assertEqual([{deps, [{<<"dep1">>, {pkg, <<"dep1">>, <<"1.0.0">>}, 0}]},
                  {plugins, []}], Written),
    ?assertEqual([{pkg_hash, [{deps, [{<<"dep1">>, <<"old-hash">>}]},
                              {plugins, []}]},
                  {pkg_hash_ext, [{deps, [{<<"dep1">>, <<"new-hash">>}]},
                                  {plugins, []}]}],
                 Attrs).

version_1_2(Config) ->
    %% Current version just dumps the locks as is on disk.
    LockFile = filename:join(?config(priv_dir, Config), "version_1_2"),
    Locks = [{<<"app1">>, {git,"some_url", {ref,"some_ref"}}, 2},
             {<<"app2">>, {git,"some_url", {ref,"some_ref"}}, 0},
             {<<"app3">>, {hg,"some_url", {ref,"some_ref"}}, 1},
             {<<"pkg1">>,{pkg,<<"name">>,<<"0.1.6">>},3},
             {<<"pkg2">>,{pkg,<<"name1">>,<<"1.1.6">>},2},
             {<<"pkg3">>,{pkg,<<"name2">>,<<"3.0.6">>},1}
            ],
    ExpandedNull = [
        {<<"app1">>, {git,"some_url", {ref,"some_ref"}}, 2},
        {<<"app2">>, {git,"some_url", {ref,"some_ref"}}, 0},
        {<<"app3">>, {hg,"some_url", {ref,"some_ref"}}, 1},
        {<<"pkg1">>,{pkg,<<"name">>,<<"0.1.6">>,undefined, undefined},3},
        {<<"pkg2">>,{pkg,<<"name1">>,<<"1.1.6">>,undefined, undefined},2},
        {<<"pkg3">>,{pkg,<<"name2">>,<<"3.0.6">>,undefined, undefined},1}
    ],
    %% Simulate a beta lockfile
    file:write_file(LockFile, io_lib:format("~p.~n", [Locks])),
    %% No properties fetched from a beta lockfile, expand locks
    %% to undefined
    ?assertEqual({ExpandedNull, []}, rebar_config:consult_lock_file(LockFile)),
    %% Adding hash data
    Hashes = [{<<"pkg1">>, <<"tarballhash">>},
              {<<"pkg3">>, <<"otherhash">>}],
    ExtHashes = [{<<"pkg1">>, <<"outer_tarballhash">>},
                 {<<"pkg3">>, <<"outer_otherhash">>}],
    ExpandedLocks = [
        {<<"app1">>, {git,"some_url", {ref,"some_ref"}}, 2},
        {<<"app2">>, {git,"some_url", {ref,"some_ref"}}, 0},
        {<<"app3">>, {hg,"some_url", {ref,"some_ref"}}, 1},
        {<<"pkg1">>,{pkg,<<"name">>,<<"0.1.6">>,<<"tarballhash">>, <<"outer_tarballhash">>},3},
        {<<"pkg2">>,{pkg,<<"name1">>,<<"1.1.6">>,undefined, undefined},2},
        {<<"pkg3">>,{pkg,<<"name2">>,<<"3.0.6">>,<<"otherhash">>, <<"outer_otherhash">>},1}
    ],
    file:write_file(LockFile,
                    io_lib:format("~p.~n~p.~n",
                                  [{"1.2.0", Locks},
                                   [{pkg_hash, Hashes}, {pkg_hash_ext, ExtHashes}]])),
    ?assertEqual({ExpandedLocks, []}, rebar_config:consult_lock_file(LockFile)),
    %% Then check that we can reverse that
    file:write_file(LockFile,
                    io_lib:format("~p.~n~p.~n",
                                  [{"1.2.0", Locks},
                                   [{pkg_hash, Hashes}, {pkg_hash_ext, ExtHashes}]])),
    ?assertEqual({ExpandedLocks, []}, rebar_config:consult_lock_file(LockFile)).

version_1_1(Config) ->
    LockFile = filename:join(?config(priv_dir, Config), "version_1_1"),
    Locks = [{<<"app1">>, {git, "some_url", {ref, "some_ref"}}, 0},
             {<<"pkg1">>, {pkg, <<"name">>, <<"0.1.6">>}, 1}],
    file:write_file(LockFile, io_lib:format("~p.~n", [{"1.1.0", Locks}])),
    ?assertEqual({[{<<"app1">>, {git, "some_url", {ref, "some_ref"}}, 0},
                  {<<"pkg1">>, {pkg, <<"name">>, <<"0.1.6">>,
                                 undefined, undefined}, 1}], []},
                 rebar_config:consult_lock_file(LockFile)).

beta_version(Config) ->
    %% Current version just dumps the locks as is on disk.
    LockFile = filename:join(?config(priv_dir, Config), "beta_version"),
    Locks = [{<<"app1">>, {git,"some_url", {ref,"some_ref"}}, 2},
             {<<"app2">>, {git,"some_url", {ref,"some_ref"}}, 0},
             {<<"app3">>, {hg,"some_url", {ref,"some_ref"}}, 1},
             {<<"pkg1">>,{pkg,<<"name">>,<<"0.1.6">>},3}],
    ExpandedLocks = [
        {<<"app1">>, {git,"some_url", {ref,"some_ref"}}, 2},
        {<<"app2">>, {git,"some_url", {ref,"some_ref"}}, 0},
        {<<"app3">>, {hg,"some_url", {ref,"some_ref"}}, 1},
        {<<"pkg1">>,{pkg,<<"name">>,<<"0.1.6">>,undefined, undefined},3}
    ],
    file:write_file(LockFile, io_lib:format("~p.~n", [Locks])),
    ?assertEqual({ExpandedLocks, []}, rebar_config:consult_lock_file(LockFile)).

future_versions_no_attrs(Config) ->
    %% Future versions will keep the same core attribute in there, but
    %% will do so under a new format bundled with a version and potentially
    %% some trailing attributes
    LockFile = filename:join(?config(priv_dir, Config), "future_versions"),
    Locks = [{<<"app1">>, {git,"some_url", {ref,"some_ref"}}, 2},
             {<<"app2">>, {git,"some_url", {ref,"some_ref"}}, 0},
             {<<"app3">>, {hg,"some_url", {ref,"some_ref"}}, 1},
             {<<"pkg1">>, {pkg,<<"name">>,<<"0.1.6">>},3}],
    ExpandedLocks = [{<<"app1">>, {git,"some_url", {ref,"some_ref"}}, 2},
                     {<<"app2">>, {git,"some_url", {ref,"some_ref"}}, 0},
                     {<<"app3">>, {hg,"some_url", {ref,"some_ref"}}, 1},
                     {<<"pkg1">>, {pkg,<<"name">>,<<"0.1.6">>,undefined, undefined},3}],
    LockData = {"3.5.2", Locks},
    file:write_file(LockFile, io_lib:format("~p.~n", [LockData])),
    ?assertEqual({ExpandedLocks, []}, rebar_config:consult_lock_file(LockFile)).

future_versions_attrs(Config) ->
    %% Future versions will keep the same core attribute in there, but
    %% will do so under a new format bundled with a version and potentially
    %% some trailing attributes
    LockFile = filename:join(?config(priv_dir, Config), "future_versions"),
    Locks = [{<<"app1">>, {git,"some_url", {ref,"some_ref"}}, 2},
             {<<"app2">>, {git,"some_url", {ref,"some_ref"}}, 0},
             {<<"app3">>, {hg,"some_url", {ref,"some_ref"}}, 1},
             {<<"pkg1">>,{pkg,<<"name">>,<<"0.1.6">>},3}],
    ExpandedLocks = [{<<"app1">>, {git,"some_url", {ref,"some_ref"}}, 2},
                     {<<"app2">>, {git,"some_url", {ref,"some_ref"}}, 0},
                     {<<"app3">>, {hg,"some_url", {ref,"some_ref"}}, 1},
                     {<<"pkg1">>,{pkg,<<"name">>,<<"0.1.6">>, <<"tarballhash">>, <<"outer_tarballhash">>},3}],
    Hashes = [{<<"pkg1">>, <<"tarballhash">>}],
    ExtHashes = [{<<"pkg1">>, <<"outer_tarballhash">>}],
    LockData = {"3.5.2", Locks},
    file:write_file(LockFile,
                    io_lib:format("~p.~n~p.~ngarbage.~n",
                                  [LockData,
                                   [{a, x},
                                    {pkg_hash, Hashes},{pkg_hash_ext, ExtHashes},
                                    {b, y}]])),
    ?assertEqual({ExpandedLocks, []}, rebar_config:consult_lock_file(LockFile)).
