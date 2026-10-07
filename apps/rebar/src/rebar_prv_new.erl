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

-module(rebar_prv_new).

-behaviour(provider).

-export([init/1,
         cli/0,
         do/1,
         help/2,
         format_error/1]).

-include("rebar.hrl").
-include_lib("providers/include/providers.hrl").

-define(PROVIDER, new).
-define(DEPS, []).

%% ===================================================================
%% Public API
%% ===================================================================

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([
        {name, ?PROVIDER},
        {module, ?MODULE},
        {bare, true},
        {deps, ?DEPS}]),
    State1 = rebar_state:add_provider(State, Provider),
    {ok, State1}.

-spec cli() -> argparse:command().
cli() ->
    #{help => "Create new project from templates.",
      arguments => [
        #{name => list,
          short => $l,
          long => "-list",
          type => boolean,
          help => "list available templates"},
        #{name => force,
          short => $f,
          long => "-force",
          type => boolean,
          help => "overwrite existing files"},
        #{name => template,
          type => string,
          required => false,
          help => "Template name. "
                  "See available templates with: `rebar new --list`"},
        #{name => vars,
          type => string,
          nargs => list,
          required => false,
          action => append,
          default => [],
          help => "Template options. Valid options: [var=foo,...]"}
    ]}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    {Args, _} = rebar_state:command_parsed_args(State),
    case proplists:get_value(list, Args, false) of
        true ->
            show_short_templates(list_templates(State)),
            {ok, State};
        false ->
            TemplateName = proplists:get_value(template, Args),
            Opts = lists:append(proplists:get_value(vars, Args, [])),
            case {TemplateName, Opts} of
                {undefined, _} ->
                    ?PRV_ERROR(template_required);
                {TemplateName1, Opts1} ->
                    case lists:keyfind(TemplateName1, 1, list_templates(State)) of
                        false ->
                            ?PRV_ERROR({template_not_found, TemplateName1});
                        _ ->
                            Force = is_forced(State),
                            ok = rebar_templater:new(TemplateName1, parse_opts(Opts1), Force, State),
                            {ok, State}
                    end
            end
    end.

-spec help([string()], rebar_state:t()) -> {ok, rebar_state:t()} | {error, term()}.
help([TemplateName], State) ->
    case lists:keyfind(TemplateName, 1, list_templates(State)) of
        false ->
            ?PRV_ERROR({template_not_found, TemplateName});
        Term ->
            show_template(Term),
            {ok, State}
    end;
help(Args, _State) ->
    ?PRV_ERROR({invalid_help_args, Args}).

-spec format_error(any()) -> iolist().
format_error({consult, File, Reason}) ->
    io_lib:format("Error consulting file at ~ts for reason ~p", [File, Reason]);
format_error({template_not_found, Name}) ->
    io_lib:format("Template '~ts' not found. See available templates with: `rebar new --list`.", [Name]);
format_error(template_required) ->
    "Template name is required unless --list is used.";
format_error({invalid_help_args, Args}) ->
    io_lib:format("Expected one template name, got ~p.", [Args]);
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

%% ===================================================================
%% Internal functions
%% ===================================================================

list_templates(State) ->
    lists:foldl(fun({error, {consult, File, Reason}}, Acc) ->
                    ?WARN("Error consulting template file ~ts for reason ~p",
                          [File, Reason]),
                    Acc
                ;  (Tpl, Acc) ->
                    [Tpl|Acc]
                end, [], lists:reverse(rebar_templater:list_templates(State))).

is_forced(State) ->
    {Args, _} = rebar_state:command_parsed_args(State),
    case proplists:get_value(force, Args) of
        undefined -> false;
        _ -> true
    end.

parse_opts([]) -> [];
parse_opts([Opt|Opts]) -> [parse_first_opt(Opt, "") | parse_opts1(Opts)].

parse_opts1([]) -> [];
parse_opts1([Opt|Opts]) -> [parse_opt(Opt, "") | parse_opts1(Opts)].

%% If the first argument meets no '=', we got a default 'name' argument
parse_first_opt("", Acc) -> {name, lists:reverse(Acc)};
parse_first_opt("="++Rest, Acc) -> parse_opt("="++Rest, Acc);
parse_first_opt([H|Str], Acc) -> parse_first_opt(Str, [H|Acc]).

%% We convert to atoms dynamically. Horrible in general, but fine in a
%% build system's templating tool.
parse_opt("", Acc) -> {list_to_atom(lists:reverse(Acc)), "true"};
parse_opt("="++Rest, Acc) -> {list_to_atom(lists:reverse(Acc)), Rest};
parse_opt([H|Str], Acc) -> parse_opt(Str, [H|Acc]).

show_short_templates(List) ->
    lists:map(fun show_short_template/1, lists:sort(List)).

show_short_template({Name, Type, _Location, Description, _Vars}) ->
    io:format("~ts (~ts): ~ts~n",
              [Name,
               format_type(Type),
               format_description(Description)]).

show_template({Name, Type, Location, Description, Vars}) ->
    io:format("~ts:~n"
              "\t~ts~n"
              "\tDescription: ~ts~n"
              "\tVariables:~n~ts~n",
              [Name,
               format_type(Type, Location),
               format_description(Description),
               format_vars(Vars)]).

format_type(escript) -> "built-in";
format_type(builtin) -> "built-in";
format_type(plugin) -> "plugin";
format_type(file) -> "custom".

format_type(escript, _) ->
    "built-in template";
format_type(builtin, _) ->
    "built-in template";
format_type(plugin, Loc) ->
    io_lib:format("plugin template (~ts)", [Loc]);
format_type(file, Loc) ->
    io_lib:format("custom template (~ts)", [Loc]).

format_description(Description) ->
    case Description of
        undefined -> "<missing description>";
        _ -> Description
    end.

format_vars(Vars) -> [format_var(Var) || Var <- Vars].

format_var({Var, Default}) ->
    io_lib:format("\t\t~p=~p~n",[Var, Default]);
format_var({Var, Default, Doc}) ->
    io_lib:format("\t\t~p=~p (~ts)~n", [Var, Default, Doc]).
