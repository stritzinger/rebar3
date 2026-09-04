%% Vendored from hex_core v0.19.0, do not edit manually

%% @doc
%% Hex HTTP API - Users.
-module(rb_hex_api_user).
-export([
    create/4,
    get/2,
    me/1,
    reset_password/2
]).

%% @doc
%% Gets the authenticated user.
%%
%% Examples:
%%
%% ```
%% > rb_hex_api_user:me(rb_hex_core:default_config()).
%% {ok, {200, ..., #{
%%      <<"email">> => <<"user@example.com">>,
%%      <<"full_name">> => <<"John Doe">>,
%%      <<"handles">> => #{...},
%%      <<"inserted_at">> => <<"2014-04-21T17:20:12Z">>,
%%      <<"level">> => <<"full">>,
%%      <<"updated_at">> => <<"2019-08-04T19:28:05Z">>,
%%      <<"url">> => <<"https://hex.pm/api/users/user">>,
%%      <<"username">> => <<"user">>
%%      }}}
%% '''
%% @end
-spec me(rb_hex_core:config()) -> rb_hex_api:response().
me(Config) when is_map(Config) ->
    rb_hex_api:get(Config, ["users", "me"]).

%% @doc
%% Creates a new user account.
%%
%% Examples:
%%
%% ```
%% > rb_hex_api_user:create(rb_hex_core:default_config(), <<"user">>, <<"hunter42">>, <<"user@example.com">>).
%% {ok, {201, ..., #{
%%      <<"email">> => <<"user@example.com">>,
%%      <<"full_name">> => <<"John Doe">>,
%%      <<"handles">> => #{...},
%%      <<"inserted_at">> => <<"2014-04-21T17:20:12Z">>,
%%      <<"level">> => <<"full">>,
%%      <<"updated_at">> => <<"2019-08-04T19:28:05Z">>,
%%      <<"url">> => <<"https://hex.pm/api/users/user">>,
%%      <<"username">> => <<"user">>
%%      }}}
%% '''
%% @end
-spec create(rb_hex_core:config(), binary(), binary(), binary()) -> rb_hex_api:response().
create(Config, Username, Password, Email) when
    is_map(Config) and is_binary(Username) and is_binary(Password) and is_binary(Email)
->
    Params = #{
        <<"username">> => Username,
        <<"password">> => Password,
        <<"email">> => Email
    },
    rb_hex_api:post(Config, ["users"], Params).

%% @doc
%% Resets the user's password.
%%
%% Examples:
%%
%% ```
%% > rb_hex_api_user:reset_password(rb_hex_core:default_config(), <<"user">>).
%% {ok, {204, ..., nil}}
%% '''
%% @end
-spec reset_password(rb_hex_core:config(), binary()) -> rb_hex_api:response().
reset_password(Config, Username) when is_map(Config) and is_binary(Username) ->
    rb_hex_api:post(Config, ["users", Username, "reset"], #{}).

%% @doc
%% Gets a user.
%%
%% Examples:
%%
%% ```
%% > rb_hex_api_user:get(rb_hex_core:default_config()).
%% {ok, {200, ..., #{
%%      <<"email">> => <<"user@example.com">>,
%%      <<"full_name">> => <<"John Doe">>,
%%      <<"handles">> => #{...},
%%      <<"inserted_at">> => <<"2014-04-21T17:20:12Z">>,
%%      <<"level">> => <<"full">>,
%%      <<"updated_at">> => <<"2019-08-04T19:28:05Z">>,
%%      <<"url">> => <<"https://hex.pm/api/users/user">>,
%%      <<"username">> => <<"user">>
%%      }}}
%% '''
%% @end
-spec get(rb_hex_core:config(), binary()) -> rb_hex_api:response().
get(Config, Username) when is_map(Config) and is_binary(Username) ->
    rb_hex_api:get(Config, ["users", Username]).
