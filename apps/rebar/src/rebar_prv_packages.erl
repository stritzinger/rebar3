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

-module(rebar_prv_packages).

-behaviour(provider).

-export([init/1,
         cli/0,
         do/1,
         format_error/1]).

-include("rebar.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-include_lib("providers/include/providers.hrl").

-define(PROVIDER, pkgs).
-define(DEPS, []).

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    State1 = rebar_state:add_provider(State,
                                      providers:create([{name, ?PROVIDER},
                                                        {module, ?MODULE},
                                                        {bare, true},
                                                        {deps, ?DEPS}])),
    {ok, State1}.

-spec cli() -> argparse:command().
cli() ->
    #{help => "List information for a package.",
      arguments => [
        #{name => package,
          type => string,
          help => "Package to fetch information for."}
    ]}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    {Args, _} = rebar_state:command_parsed_args(State),
    case proplists:get_value(package, Args, undefined) of
        undefined ->
            ?PRV_ERROR(no_package_arg);
        Name ->
            Resources = rebar_state:resources(State),
            #{repos := Repos} = rebar_resource_v2:find_resource_state(pkg, Resources),
            Results = get_package(rebar_utils:to_binary(Name), Repos),
            case lists:all(fun({_, {error, not_found}}) -> true; (_) -> false end, Results) of
                true ->
                    ?PRV_ERROR({not_found, Name});
                false ->
                    [print_packages(Result) || Result <- Results],
                    {ok, State}
            end
    end.

-spec get_package(binary(), [map()]) -> [{binary(), {ok, map()} | {error, term()}}].
get_package(Name, Repos) ->
    lists:foldl(fun(RepoConfig, Acc) ->
                        [{maps:get(name, RepoConfig), rebar_packages:get(RepoConfig, Name)} | Acc]
                end, [], Repos).


-spec format_error(any()) -> iolist().
format_error(no_package_arg) ->
    "Missing package argument to `rebar pkgs` command.";
format_error({not_found, Name}) ->
    io_lib:format("Package ~ts not found in any repo.", [Name]);
format_error(unknown) ->
    "Something went wrong with fetching package metadata.".


print_packages({RepoName, {error, not_found}}) ->
    ?CONSOLE("~ts: Package not found in this repo.~n", [RepoName]);
print_packages({RepoName, {error, _}}) ->
    ?CONSOLE("~ts: Error fetching from this repo.~n", [RepoName]);
print_packages({RepoName, {ok, #{<<"name">> := Name,
                                 <<"meta">> := Meta,
                                 <<"releases">> := Releases}}}) ->
    Description = maps:get(<<"description">>, Meta, ""),
    Licenses = join(maps:get(<<"licenses">>, Meta, []), <<", ">>),
    Links = join_map(maps:get(<<"links">>, Meta, []), <<"\n        ">>),
    Versions = [V || #{<<"version">> := V} <- Releases],
    VsnStr = join(Versions, <<", ">>),
    ?CONSOLE("~ts:~n"
             "    Name: ~ts~n"
             "    Description: ~ts~n"
             "    Licenses: ~ts~n"
             "    Links:~n        ~ts~n"
             "    Versions: ~ts~n", [RepoName, Name, Description, Licenses, Links, VsnStr]);
print_packages(_) ->
    ok.

-spec join([binary()], binary()) -> binary().
join([], _Sep) ->
    <<>>;
join([Bin], _Sep) ->
    <<Bin/binary>>;
join([Bin | T], Sep) ->
    <<Bin/binary, Sep/binary, (join(T, Sep))/binary>>.

-spec join_map(map(), binary()) -> binary().
join_map(Map, Sep) ->
    join_tuple_list(maps:to_list(Map), Sep).

join_tuple_list([], _Sep) ->
    <<>>;
join_tuple_list([{K, V}], _Sep) ->
    <<K/binary, ": ", V/binary>>;
join_tuple_list([{K, V} | T], Sep) ->
    <<K/binary, ": ", V/binary, Sep/binary, (join_tuple_list(T, Sep))/binary>>.
