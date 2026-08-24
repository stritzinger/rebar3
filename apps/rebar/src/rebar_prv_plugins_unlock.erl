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

-module(rebar_prv_plugins_unlock).

-behaviour(provider).

-export([init/1,
         cli/0,
         do/1,
         format_error/1]).

-include("rebar.hrl").
-include_lib("providers/include/providers.hrl").

-define(PROVIDER, unlock).
-define(NAMESPACE, plugins).
-define(DEPS, []).

init(State) ->
    State1 = rebar_state:add_provider(
        State,
        providers:create([{name, ?PROVIDER},
                          {module, ?MODULE},
                          {namespace, ?NAMESPACE},
                          {bare, true},
                          {deps, ?DEPS}])),
    {ok, State1}.

cli() ->
    #{help => "Unlock plugins.",
      arguments => [
        #{name => all,
          short => $a,
          long => "-all",
          type => boolean,
          help => "Unlock all plugins."},
        #{name => plugin,
          type => string,
          nargs => list,
          required => false,
          action => append,
          default => [],
          help => "List of plugins to unlock."}
    ]}.

do(State) ->
    Dir = rebar_state:dir(State),
    LockFile = filename:join(Dir, ?LOCK_FILE),
    case file:consult(LockFile) of
        {error, enoent} ->
            {ok, State};
        {error, Reason} ->
            ?PRV_ERROR({file, Reason});
        {ok, _} ->
            {Deps, PluginLocks} = rebar_config:consult_lock_file(LockFile),
            {All, Names} = handle_args(State),
            case {All, Names} of
                {false, []} ->
                    throw(?PRV_ERROR(no_arg));
                {true, _} ->
                    write_locks(LockFile, Deps, []),
                    {ok, rebar_state:set(State, {plugin_locks, default}, [])};
                {false, _} ->
                    NewPluginLocks = [Lock || Lock = {Name, _, _} <- PluginLocks,
                                               not lists:member(Name, Names)],
                    case NewPluginLocks =:= PluginLocks of
                        true ->
                            {ok, State};
                        false ->
                            write_locks(LockFile, Deps, NewPluginLocks),
                            {ok, rebar_state:set(State,
                                                 {plugin_locks, default},
                                                 NewPluginLocks)}
                    end
            end
    end.

format_error({file, Reason}) ->
    io_lib:format("Lock file editing failed for reason ~p", [Reason]);
format_error(no_arg) ->
    "Specify a list of plugins to unlock, or --all to unlock them all";
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

handle_args(State) ->
    {Args, _} = rebar_state:command_parsed_args(State),
    All = proplists:get_value(all, Args, false),
    Names = rebar_utils:split_comma_separated_list(
              proplists:get_value(plugin, Args, [])),
    {All, Names}.

write_locks(LockFile, [], []) ->
    file:delete(LockFile);
write_locks(LockFile, Deps, Plugins) ->
    rebar_config:write_lock_file(LockFile, [{deps, Deps}, {plugins, Plugins}]).
