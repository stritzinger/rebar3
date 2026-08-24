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

-module(rebar_prv_unlock).

-behaviour(provider).

-export([init/1,
         cli/0,
         do/1,
         format_error/1]).

-include("rebar.hrl").
-include_lib("providers/include/providers.hrl").

-define(PROVIDER, unlock).
-define(DEPS, []).

%% ===================================================================
%% Public API
%% ===================================================================

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    State1 = rebar_state:add_provider(
        State,
        providers:create([{name, ?PROVIDER},
                          {module, ?MODULE},
                          {bare, true},
                          {deps, ?DEPS}])
    ),
    {ok, State1}.

-spec cli() -> argparse:command().
cli() ->
    #{help => "Unlock dependencies.",
      arguments => [
        #{name => all,
          short => $a,
          long => "-all",
          type => boolean,
          help => "Unlock all dependencies and remove the lock file."},
        #{name => package,
          type => string,
          nargs => list,
          required => false,
          action => append,
          default => [],
          help => "List of packages to unlock."}
    ]}.

do(State) ->
    Dir = rebar_state:dir(State),
    LockFile = filename:join(Dir, ?LOCK_FILE),
    case file:consult(LockFile) of
        {error, enoent} ->
            %% Our work is done.
            {ok, State};
        {error, Reason} ->
            ?PRV_ERROR({file,Reason});
        {ok, _} ->
            {Locks, _PluginLocks} = rebar_config:consult_lock_file(LockFile),
            {ok, NewLocks} = handle_unlocks(State, Locks, LockFile),
            {ok, rebar_state:set(State, {locks, default}, NewLocks)}
    end.

-spec format_error(any()) -> iolist().
format_error({file, Reason}) ->
    io_lib:format("Lock file editing failed for reason ~p", [Reason]);
format_error(unknown_lock_format) ->
    "Lock file format unknown";
format_error(no_arg) -> 
    "Specify a list of dependencies to unlock, or --all to unlock them all";
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

handle_unlocks(State, Locks, LockFile) ->
    case handle_args(State) of
        %% a list of dependencies or --all is required
        {false, []} -> 
            throw(?PRV_ERROR(no_arg));
        %% if --all is specified, delete the lock file
        {true, _} -> 
            file:delete(LockFile),
            {ok, []};
        %% otherwise, unlock the given list of dependency names. if none are left, delete the lock file
        {false, Names} -> 
            case [Lock || Lock = {Name, _, _} <- Locks, not lists:member(Name, Names)] of
                [] ->
                    file:delete(LockFile),
                    {ok, []};
                _ when Names =:= [] -> % implicitly all locks
                    file:delete(LockFile),
                    {ok, []};
                NewLocks -> 
                    rebar_config:write_lock_file(LockFile, NewLocks),
                    {ok, NewLocks}
            end
    end.

handle_args(State) -> 
    {Args, _} = rebar_state:command_parsed_args(State),
    All = proplists:get_value(all, Args, false),
    Names = rebar_utils:split_comma_separated_list(proplists:get_value(package, Args, [])),
    {All, Names}.
