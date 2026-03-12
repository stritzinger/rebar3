%% SPDX-License-Identifier: Apache-2.0
%% SPDX-FileCopyrightText: 2026 Dipl. Phys. Peer Stritzinger GmbH

-module(rebar_legacy_cli).

-export([to_command/1, to_parse_command/1, provider_help/2]).

-include("rebar.hrl").

%% Convert a provider's legacy getopt option specs to an argparse command map.
-spec to_command(providers:t()) -> argparse:command().
to_command(Provider) ->
    command(Provider, []).

-spec to_parse_command(providers:t()) -> argparse:command().
to_parse_command(Provider) ->
    command(
      Provider,
      [#{name => help,
         short => $h,
         long => "-help",
         type => boolean,
         help => "Print this help."},
       #{name => version,
         short => $v,
         long => "-version",
         type => boolean,
         help => "Show version information."},
       #{name => task,
         type => string,
         required => false,
         help => "Task to run."},
       #{name => rest,
         type => string,
         nargs => list,
         required => false,
         help => ""}]
    ).

command(Provider, ExtraArguments) ->
    #{
        help => command_help(Provider),
        arguments => to_arguments(Provider) ++ ExtraArguments
    }.

to_arguments(Provider) ->
    Opts = case catch providers:opts(Provider) of
               List when is_list(List) -> List;
               _ -> []
           end,
    Args = [Arg || Opt <- Opts,
                   {ok, Arg} <- [safe_to_argument(Opt)]],
    sanitize_arguments(Args).

safe_to_argument(Opt) ->
    try {ok, to_argument(Opt)}
    catch
        _:_ ->
            error
    end.

%% Convert a single getopt option spec tuple into an argparse argument map.
to_argument({Name, Short, Long, ArgSpec, Help}) ->
    Base0 = #{
        name => Name,
        type => to_type(ArgSpec),
        help => to_help(Help)
    },
    Base1 = maybe_put(short, Short, Base0),
    Base2 = maybe_put(long, to_long(Long), Base1),
    add_default_and_required(ArgSpec, Base2).

%% argparse expects long options with a leading '-' (or omitted).
to_long(undefined) -> undefined;
to_long([]) -> undefined;
to_long([$- | _] = Long) -> Long;
to_long(Long) -> "-" ++ Long.

%% Keep help strings stable even when legacy providers omit text.
to_help(undefined) -> "";
to_help(Help) -> Help.

command_help(Provider) ->
    try unicode:characters_to_list(providers:desc(Provider))
    catch
        _:_ -> ""
    end.

%% getopt 'undefined' means a boolean switch.
to_type(undefined) ->
    boolean;
to_type({Type, _Default}) ->
    normalize_type(Type);
to_type(Type) ->
    normalize_type(Type).

%% argparse has no binary/utf8_binary primitive; accept strings instead.
normalize_type(binary) -> string;
normalize_type(utf8_binary) -> string;
normalize_type(boolean) -> boolean;
normalize_type(string) -> string;
normalize_type(integer) -> integer;
normalize_type(float) -> float;
normalize_type(atom) -> atom;
%% Legacy getopt providers may use custom atoms unknown to argparse.
%% Keep CLI generation resilient by treating those as string arguments.
normalize_type(Type) when is_atom(Type) -> string;
normalize_type(_Type) -> string.

%% getopt semantics:
%% - no ArgSpec/default -> flag only
%% - {Type, Default} -> optional argument with default
%% - Type -> optional option taking a value when present
add_default_and_required(undefined, Base) ->
    Base;
add_default_and_required({Type, Default}, Base) when Type =:= boolean ->
    Base#{default => Default};
add_default_and_required({Type, Default}, Base) ->
    Base#{default => Default, required => false, type => normalize_type(Type)};
add_default_and_required(boolean, Base) ->
    Base;
add_default_and_required(_Type, Base) ->
    Base#{required => false}.

%% Avoid injecting keys with undefined values into argparse maps.
maybe_put(_Key, undefined, Map) ->
    Map;
maybe_put(Key, Value, Map) ->
    Map#{Key => Value}.

sanitize_arguments(Args) ->
    %% Legacy getopt providers can reuse short switches.
    %% argparse rejects duplicate option switches during CLI validation,
    %% which can crash `rebar3 help` before fallback handling runs.
    %% Keep command generation resilient by dropping conflicting short
    %% switches from provider options while still exposing the argument itself.
    ReservedShorts = sets:from_list([$h, $v]),
    sanitize_arguments(Args, ReservedShorts, []).

sanitize_arguments([], _SeenShorts, Acc) ->
    lists:reverse(Acc);
sanitize_arguments([Arg0 | Rest], SeenShorts0, Acc) ->
    {Arg1, SeenShorts1} = sanitize_short(Arg0, SeenShorts0),
    sanitize_arguments(Rest, SeenShorts1, [Arg1 | Acc]).

sanitize_short(Arg, SeenShorts) ->
    case maps:find(short, Arg) of
        {ok, Short} ->
            case sets:is_element(Short, SeenShorts) of
                true ->
                    %% Preserve the option but remove conflicting short alias.
                    {maps:remove(short, Arg), SeenShorts};
                false ->
                    {Arg, sets:add_element(Short, SeenShorts)}
            end;
        error ->
            {Arg, SeenShorts}
    end.

%% Fallback `rebar3 help` resolver for legacy/non-bare providers.
-spec provider_help([string()], [providers:t()]) -> ok | {error, string()}.
provider_help([Task], Providers) ->
    case providers:get_provider(list_to_atom(Task), Providers, default) of
        not_found ->
            {error, "Command " ++ Task ++ " not found"};
        Provider ->
            providers:help(Provider),
            ok
    end;
provider_help([Namespace, Task], Providers) ->
    case providers:get_provider(list_to_atom(Task), Providers, list_to_atom(Namespace)) of
        not_found ->
            {error, "Command " ++ Task ++ " not found in namespace " ++ Namespace};
        Provider ->
            providers:help(Provider),
            ok
    end;
provider_help(Path, _Providers) ->
    {error, "Command " ++ string:join(Path, " ") ++ " not found"}.
