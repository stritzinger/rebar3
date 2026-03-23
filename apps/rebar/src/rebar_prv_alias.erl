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
 
%%% @doc Meta-provider that dynamically compiles providers
%%% to run aliased commands.
%%%
%%% This is hackish and out-there, but this module has graduated
%%% from a plugin at https://github.com/tsloughter/rebar_alias after
%%% years of stability. Only some error checks were added
-module(rebar_prv_alias).

-behaviour(provider).

-export([init/1, cli/0, alias_cli/1, do/1, format_error/1]).
-include("rebar.hrl").

-define(PROVIDER, alias).
-define(CREATED_ALIASES_KEY, '_rebar_prv_alias_created_aliases').

%% ===================================================================
%% Public API
%% ===================================================================
-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Aliases = rebar_state:get(State, alias, []),
    {StateWithAliases, AliasesDefs}
        = lists:foldl(
              fun({Alias, Cmds}, {StateAcc, AliasesDefsAcc} = Acc) ->
                  case validate_provider(Alias, Cmds, State) of
                      true ->
                          StateWithAlias = init_alias(Alias, Cmds, StateAcc),
                          AliasesDefsWithAlias = [{Alias, Cmds} | AliasesDefsAcc],
                          {StateWithAlias, AliasesDefsWithAlias};
                      false ->
                          Acc
                  end
              end,
              {State, []},
              Aliases
          ),
    AliasProvider = providers:create([{name, ?PROVIDER},
                                      {module, ?MODULE},
                                      {bare, true},
                                      {deps, []}]),
    StateWithProvider = rebar_state:add_provider(StateWithAliases, AliasProvider),
    StateWithAliasesDefs = rebar_state:set(StateWithProvider, ?CREATED_ALIASES_KEY, AliasesDefs),
    {ok, StateWithAliasesDefs}.

-spec cli() -> argparse:command().
cli() ->
    #{help => "List aliases' definitions.",
      arguments => []}. 

-spec do(rebar_state:t()) -> {ok, rebar_state:t()}.
do(State) ->
    lists:foreach(
        fun ({Alias, Cmds}) ->
            AliasStr = atom_to_list(Alias),
            CmdsStr = cmds_string(Cmds),
            ?CONSOLE("~ts=~ts", [AliasStr, CmdsStr])
        end,
        rebar_state:get(State, ?CREATED_ALIASES_KEY, [])
    ),
    {ok, State}.

-spec format_error(any()) -> iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

-dialyzer([{no_opaque, init_alias/3}, {no_return, init_alias/3}]). % warnings relate to use of opaque structures in :forms
init_alias(Alias, Cmds, State) ->
    Module = list_to_atom("rebar_prv_alias_" ++ atom_to_list(Alias)),

    MF = module(Module),
    EF = exports(),
    CF = cli_func(Cmds),
    FF = do_func(Cmds),

    {ok, _, Bin} = compile:forms([MF, EF, CF, FF]),
    code:load_binary(Module, "none", Bin),

    Provider = providers:create([
            {name, Alias},
            {module, Module},
            {bare, true},
            {deps, []}]),
    rebar_state:add_provider(State, Provider).

validate_provider(Alias, Cmds, State) ->
    %% This would be caught and prevented anyway, but the warning
    %% is friendlier
    case providers:get_provider(Alias, rebar_state:providers(State)) of
        not_found ->
            %% check for circular deps in the alias.
            case not proplists:is_defined(Alias, Cmds) of
                true -> true;
                false ->
                    ?WARN("Alias ~p contains itself and would never "
                          "terminate. It will be ignored.",
                          [Alias]),
                    false
            end;
        _ ->
            ?WARN("Alias ~p is already the name of a command in "
                  "the default namespace and will be ignored.",
                  [Alias]),
            false
    end.

-spec alias_cli([term()]) -> argparse:command().
alias_cli(Cmds) ->
    #{help => lists:flatten(desc(Cmds)),
      arguments => []}.

-dialyzer({no_unused, desc/1}). % required since we suppress warnings for init_alias/3
desc(Cmds) ->
    "Equivalent to running: rebar3 do "
        ++ cmds_string(Cmds).

cmds_string(Cmds) ->
    rebar_string:join(lists:map(fun to_desc/1, Cmds), ",").

to_desc({Cmd, []}) ->
    cmd_to_list(Cmd);
to_desc({Cmd, Args}) when is_list(Args) ->
    cmd_to_list(Cmd) ++ " " ++ Args;
to_desc({Namespace, Cmd}) ->
    atom_to_list(Namespace) ++ " " ++ atom_to_list(Cmd);
to_desc({Namespace, Cmd, Args}) ->
    atom_to_list(Namespace) ++ " " ++ atom_to_list(Cmd) ++ " " ++ Args;
to_desc(Cmd) ->
    cmd_to_list(Cmd).

cmd_to_list(Cmd) when is_atom(Cmd) ->
    atom_to_list(Cmd);
cmd_to_list(Cmd) when is_list(Cmd) ->
    Cmd.

module(Name) ->
    {attribute, 1, module, Name}.

exports() ->
    {attribute, 1, export, [{cli, 0}, {do, 1}]}.

cli_func(Cmds) ->
    {function, 1, cli, 0,
     [{clause, 1,
       [],
       [],
       [{call, 1,
         {remote, 1, {atom, 1, rebar_prv_alias}, {atom, 1, alias_cli}},
         [make_args(Cmds)]}]}]}.

do_func(Cmds) ->
    {function, 1, do, 1,
     [{clause, 1,
       [{var, 1, 'State'}],
       [],
       [{call, 1,
         {remote, 1, {atom, 1, rebar_prv_do}, {atom, 1, do_tasks}},
         [make_args(Cmds), {var, 1, 'State'}]}]}]}.

make_args(Cmds) ->
    make_list(
      lists:map(fun make_tuple/1,
                lists:map(fun make_arg/1, Cmds))).

make_arg({Namespace, Command, Args}) when is_atom(Namespace), is_atom(Command) ->
    {make_atom(Namespace),
     make_atom(Command),
     make_list([make_string(A) || A <- split_args(Args)])};
make_arg({Namespace, Command}) when is_atom(Namespace), is_atom(Command) ->
    {make_atom(Namespace), make_atom(Command)};
make_arg({Cmd, Args}) ->
    {make_string(Cmd), make_list([make_string(A) || A <- split_args(Args)])};
make_arg(Cmd) ->
    {make_string(Cmd), make_list([])}.

make_tuple(Tuple) ->
    {tuple, 1, tuple_to_list(Tuple)}.

make_list(List) ->
    lists:foldr(
      fun(Elem, Acc) -> {cons, 1, Elem, Acc} end,
      {nil, 1},
      List).

make_string(Atom) when is_atom(Atom) ->
    make_string(atom_to_list(Atom));
make_string(String) when is_list(String) ->
    {string, 1, String}.

make_atom(Atom) when is_atom(Atom) ->
    {atom, 1, Atom}.

%% In case someone used the long option format, the option needs to get
%% separated from its value.
split_args(Args) ->
    rebar_string:lexemes(
      lists:map(fun($=) -> 32; (C) -> C end, Args),
      " ").
