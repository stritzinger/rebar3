%% Vendored from hex_core v0.19.0, do not edit manually

%% @doc
%% Hex HTTP API - Packages.
-module(rb_hex_api_package).
-export([get/2, search/3]).

%% @doc
%% Gets a package.
%%
%% Examples:
%%
%% ```
%% > rb_hex_api_package:get(rb_hex_core:default_config(), <<"package">>).
%% {ok, {200, ..., #{
%%     <<"name">> => <<"package1">>,
%%     <<"meta">> => #{
%%         <<"description">> => ...,
%%         <<"licenses">> => ...,
%%         <<"links">> => ...,
%%         <<"maintainers">> => ...
%%     },
%%     ...,
%%     <<"releases">> => [
%%         #{<<"url">> => ..., <<"version">> => <<"0.5.0">>}],
%%         #{<<"url">> => ..., <<"version">> => <<"1.0.0">>}],
%%         ...
%%     ]}}}
%% '''
%% @end
-spec get(rb_hex_core:config(), binary()) -> rb_hex_api:response().
get(Config, Name) when is_map(Config) and is_binary(Name) ->
    Path = rb_hex_api:build_repository_path(Config, ["packages", Name]),
    rb_hex_api:get(Config, Path).

%% @doc
%% Searches packages.
%%
%% Examples:
%%
%% ```
%% > rb_hex_api_package:search(rb_hex_core:default_config(), <<"package">>, [{page, 1}]).
%% {ok, {200, ..., [
%%     #{<<"name">> => <<"package1">>, ...},
%%     ...
%% ]}}
%% '''
-spec search(rb_hex_core:config(), binary(), [{term(), term()}]) -> rb_hex_api:response().
search(Config, Query, SearchParams) when
    is_map(Config) and is_binary(Query) and is_list(SearchParams)
->
    QueryString = rb_hex_api:encode_query_string([{search, Query} | SearchParams]),
    Path = rb_hex_api:join_path_segments(rb_hex_api:build_repository_path(Config, ["packages"])),
    PathQuery = <<Path/binary, "?", QueryString/binary>>,
    rb_hex_api:get(Config, PathQuery).
