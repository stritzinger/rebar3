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

%% Derived from hex_core v0.7.1 for extra flexibility.

-module(rebar_httpc_adapter).
-behaviour(rb_hex_http).
-export([request/5, request_to_file/6]).

%%====================================================================
%% API functions
%%====================================================================

request(Method, URI, ReqHeaders, Body, AdapterConfig) ->
    case os:getenv("REBAR_OFFLINE") of
        "1" ->
            {error, {offline, URI}};
        _ ->
            request_online(Method, URI, ReqHeaders, Body, AdapterConfig)
    end.

request_to_file(Method, URI, ReqHeaders, Body, Filename, AdapterConfig) when is_binary(URI) ->
    case os:getenv("REBAR_OFFLINE") of
        "1" ->
            {error, {offline, URI}};
        _ ->
            request_online_to_file(Method, URI, ReqHeaders, Body, Filename, AdapterConfig)
    end.

%%====================================================================
%% Internal functions
%%====================================================================

request_online(Method, URI, ReqHeaders, Body, AdapterConfig) ->
    Profile = maps:get(profile, AdapterConfig, default),
    Request = build_request(URI, ReqHeaders, Body),
    SSLOpts = [{ssl, rebar_utils:ssl_opts(URI)}],
    case httpc:request(Method, Request, SSLOpts, [{body_format, binary}], Profile) of
        {ok, {{_, StatusCode, _}, RespHeaders, RespBody}} ->
            RespHeaders2 = load_headers(RespHeaders),
            {ok, {StatusCode, RespHeaders2, RespBody}};
        {error, Reason} -> {error, Reason}
    end.

request_online_to_file(Method, URI, ReqHeaders, Body, Filename, AdapterConfig) ->
    Profile = maps:get(profile, AdapterConfig, default),
    Request = build_request(URI, ReqHeaders, Body),
    SSLOpts = [{ssl, rebar_utils:ssl_opts(URI)}],
    case
        httpc:request(
            Method,
            Request,
            SSLOpts,
            [{stream, unicode:characters_to_list(Filename)}],
            Profile
        )
    of
        {ok, saved_to_file} ->
            {ok, {200, #{}}};
        {ok, {{_, StatusCode, _}, RespHeaders, _RespBody}} ->
            RespHeaders2 = load_headers(RespHeaders),
            {ok, {StatusCode, RespHeaders2}};
        {error, Reason} ->
            {error, Reason}
    end.

build_request(URI, ReqHeaders, Body) ->
    build_request2(binary_to_list(URI), dump_headers(ReqHeaders), Body).

build_request2(URI, ReqHeaders, undefined) ->
    {URI, ReqHeaders};
build_request2(URI, ReqHeaders, {ContentType, Body}) ->
    {URI, ReqHeaders, ContentType, Body}.

dump_headers(Map) ->
    maps:fold(fun(K, V, Acc) ->
        [{binary_to_list(K), binary_to_list(V)} | Acc] end, [], Map).

load_headers(List) ->
    lists:foldl(fun({K, V}, Acc) ->
        maps:put(list_to_binary(K), list_to_binary(V), Acc) end, #{}, List).
