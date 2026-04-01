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

%% Creating a new module for the formater to keep stuff clean.
%% Might move it inside rebar_log.erl in the future if module is small enough

-module(rebar_log_formater).

-export([format/2]).

%% =============================================================================
%% Types
%% =============================================================================

-type level() :: error | warning | notice | info | debug.
-type intensity() ::  low | high | none.
-type color() :: $r | $R | $b | $B | $g | $G | $m | $M | $c | $C.

%% =============================================================================
%% Macros
%% =============================================================================

-define(PREFIX, "===> ").
-define(RESET, "~!!").
-define(BOLD, "~!^").

%% =============================================================================
%% Public API
%% =============================================================================

-spec format(logger:log_event(), logger:formatter_config()) -> unicode:chardata().
format(#{level := Level, msg := Msg}, #{intensity := Intensity}) ->
    FullOutput = [msg(Msg), "\n"],
    colorize(Intensity, Level, FullOutput).

%% =============================================================================
%% Internal functions
%% =============================================================================

-spec msg(Msg) -> list() when
      Msg :: {report, logger:report()}
             | {string, unicode:chardata()}
             | {io:format(), [term()]}.
msg({report, Report}) ->
    io_lib:format("~p", [Report]);
msg({string, Chardata}) ->
    Chardata;
msg({Format, Terms}) ->
    io_lib:format(Format, Terms).

-spec level_to_color(level()) -> color().
level_to_color(error) ->
    $R;
level_to_color(warning) ->
    $m;
level_to_color(notice) ->
    $g;
level_to_color(info) ->
    $g;
level_to_color(debug) ->
    $c.

-spec bold(level()) -> boolean().
bold(error) -> true;
bold(_) -> false.

-spec colorize(intensity(), level(), list()) -> list().
colorize(none, Level, Text) ->
    case bold(Level) of
        false -> Text;
        true -> lists:flatten(cf:format(?BOLD ++ "~ts", [Text]))
    end;
colorize(Intensity, Level, Text) ->
    Color = case Intensity of
                none -> "";
                _ -> "~!" ++ [level_to_color(Level)]
            end,
    FmtMsg = message_format(Intensity, bold(Level)),
    lists:flatten(cf:format(Color ++ FmtMsg, [?PREFIX, Text])).

-spec message_format(intensity(), boolean()) -> string().
message_format(high, false) ->
    "~ts~ts";
message_format(high, true) ->
    "~ts" ++ ?BOLD ++ "~ts";
message_format(low, false) ->
    "~ts" ++ ?RESET ++ "~ts";
message_format(low, true) ->
    "~ts" ++ ?RESET ++ ?BOLD ++ "~ts".
