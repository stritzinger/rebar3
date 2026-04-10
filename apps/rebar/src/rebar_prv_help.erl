%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et

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

-module(rebar_prv_help).

-behaviour(provider).

-export([init/1,
         cli/0,
         do/1,
         format_error/1]).

-include("rebar.hrl").

-define(PROVIDER, help).
-define(DEPS, []).

%% ===================================================================
%% Public API
%% ===================================================================

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    State1 = rebar_state:add_provider(State, providers:create([{name, ?PROVIDER},
                                                               {module, ?MODULE},
                                                               {bare, true},
                                                               {deps, ?DEPS}])),
    {ok, State1}.

-spec cli() -> argparse:command().
cli() ->
    #{help => "Display a list of tasks or help for a given task or subtask.",
      arguments => [
        #{name => help_task,
          type => string,
          nargs => list,
          required => false,
          help => "Task to print help for."}
    ]}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    case rebar_state:command_args(State) of
        [] ->
            help(State),
            {ok, State};
        HelpPath when is_list(HelpPath), length(HelpPath) =< 2 ->
            command_help(HelpPath, State);
        _ ->
            {error, "Too many arguments given. " ++
                 "Usage: rebar3 help [<namespace>] <task>"}
    end.

-spec format_error(any()) -> iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

%%
%% print help/usage string
%%
help(State) ->
    io:format("~ts",
              [argparse:help(
                  rebar_cli:global_cli(rebar_state:providers(State)),
                  #{progname => "rebar3"})]).

command_help(Path, State) ->
    Providers = rebar_state:providers(State),
    Cli = rebar_cli:global_cli(Providers),
    case command_exists(Path, Cli) of
        true ->
            HelpText = argparse:help(Cli, #{progname => "rebar3", command => Path}),
            io:format("~ts", [HelpText]),
            {ok, State};
        false ->
            help_not_found(Path)
    end.

command_exists([], _Cli) ->
    true;
command_exists([Segment | Rest], Cli) ->
    case maps:find(commands, Cli) of
        {ok, Commands} ->
            case maps:find(Segment, Commands) of
                {ok, Subcommand} ->
                    command_exists(Rest, Subcommand);
                error ->
                    false
            end;
        error ->
            false
    end.

help_not_found([Command]) ->
    {error, "Command " ++ Command ++ " not found"};
help_not_found([Namespace, Command]) ->
    {error, "Command " ++ Command ++ " not found in namespace " ++ Namespace}.
