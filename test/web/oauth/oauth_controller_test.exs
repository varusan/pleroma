# Pleroma: A lightweight social networking server
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.OAuth.OAuthControllerTest do
  use Pleroma.Web.ConnCase
  import Pleroma.Factory
  import Mock

  alias Pleroma.Registration
  alias Pleroma.Repo
  alias Pleroma.Web.OAuth.Authorization
  alias Pleroma.Web.OAuth.Token

  @oauth_config_path [:oauth2, :issue_new_refresh_token]
  @session_opts [
    store: :cookie,
    key: "_test",
    signing_salt: "cooldude"
  ]

  describe "in OAuth consumer mode, " do
    setup do
      oauth_consumer_strategies_path = [:auth, :oauth_consumer_strategies]
      oauth_consumer_strategies = Pleroma.Config.get(oauth_consumer_strategies_path)
      Pleroma.Config.put(oauth_consumer_strategies_path, ~w(twitter facebook))

      on_exit(fn ->
        Pleroma.Config.put(oauth_consumer_strategies_path, oauth_consumer_strategies)
      end)

      [
        app: insert(:oauth_app),
        conn:
          build_conn()
          |> Plug.Session.call(Plug.Session.init(@session_opts))
          |> fetch_session()
      ]
    end

    test "GET /oauth/authorize renders auth forms, including OAuth consumer form", %{
      app: app,
      conn: conn
    } do
      conn =
        get(
          conn,
          "/oauth/authorize",
          %{
            "response_type" => "code",
            "client_id" => app.client_id,
            "redirect_uri" => app.redirect_uris,
            "scope" => "read"
          }
        )

      assert response = html_response(conn, 200)
      assert response =~ "Sign in with Twitter"
      assert response =~ o_auth_path(conn, :prepare_request)
    end

    test "GET /oauth/prepare_request encodes parameters as `state` and redirects", %{
      app: app,
      conn: conn
    } do
      conn =
        get(
          conn,
          "/oauth/prepare_request",
          %{
            "provider" => "twitter",
            "authorization" => %{
              "scope" => "read follow",
              "client_id" => app.client_id,
              "redirect_uri" => app.redirect_uris,
              "state" => "a_state"
            }
          }
        )

      assert response = html_response(conn, 302)

      redirect_query = URI.parse(redirected_to(conn)).query
      assert %{"state" => state_param} = URI.decode_query(redirect_query)
      assert {:ok, state_components} = Poison.decode(state_param)

      expected_client_id = app.client_id
      expected_redirect_uri = app.redirect_uris

      assert %{
               "scope" => "read follow",
               "client_id" => ^expected_client_id,
               "redirect_uri" => ^expected_redirect_uri,
               "state" => "a_state"
             } = state_components
    end

    test "with user-bound registration, GET /oauth/<provider>/callback redirects to `redirect_uri` with `code`",
         %{app: app, conn: conn} do
      registration = insert(:registration)

      state_params = %{
        "scope" => Enum.join(app.scopes, " "),
        "client_id" => app.client_id,
        "redirect_uri" => app.redirect_uris,
        "state" => ""
      }

      with_mock Pleroma.Web.Auth.Authenticator,
        get_registration: fn _ -> {:ok, registration} end do
        conn =
          get(
            conn,
            "/oauth/twitter/callback",
            %{
              "oauth_token" => "G-5a3AAAAAAAwMH9AAABaektfSM",
              "oauth_verifier" => "QZl8vUqNvXMTKpdmUnGejJxuHG75WWWs",
              "provider" => "twitter",
              "state" => Poison.encode!(state_params)
            }
          )

        assert response = html_response(conn, 302)
        assert redirected_to(conn) =~ ~r/#{app.redirect_uris}\?code=.+/
      end
    end

    test "with user-unbound registration, GET /oauth/<provider>/callback renders registration_details page",
         %{app: app, conn: conn} do
      registration = insert(:registration, user: nil)

      state_params = %{
        "scope" => "read write",
        "client_id" => app.client_id,
        "redirect_uri" => app.redirect_uris,
        "state" => "a_state"
      }

      with_mock Pleroma.Web.Auth.Authenticator,
        get_registration: fn _ -> {:ok, registration} end do
        conn =
          get(
            conn,
            "/oauth/twitter/callback",
            %{
              "oauth_token" => "G-5a3AAAAAAAwMH9AAABaektfSM",
              "oauth_verifier" => "QZl8vUqNvXMTKpdmUnGejJxuHG75WWWs",
              "provider" => "twitter",
              "state" => Poison.encode!(state_params)
            }
          )

        assert response = html_response(conn, 200)
        assert response =~ ~r/name="op" type="submit" value="register"/
        assert response =~ ~r/name="op" type="submit" value="connect"/
        assert response =~ Registration.email(registration)
        assert response =~ Registration.nickname(registration)
      end
    end

    test "on authentication error, GET /oauth/<provider>/callback redirects to `redirect_uri`", %{
      app: app,
      conn: conn
    } do
      state_params = %{
        "scope" => Enum.join(app.scopes, " "),
        "client_id" => app.client_id,
        "redirect_uri" => app.redirect_uris,
        "state" => ""
      }

      conn =
        conn
        |> assign(:ueberauth_failure, %{errors: [%{message: "(error description)"}]})
        |> get(
          "/oauth/twitter/callback",
          %{
            "oauth_token" => "G-5a3AAAAAAAwMH9AAABaektfSM",
            "oauth_verifier" => "QZl8vUqNvXMTKpdmUnGejJxuHG75WWWs",
            "provider" => "twitter",
            "state" => Poison.encode!(state_params)
          }
        )

      assert response = html_response(conn, 302)
      assert redirected_to(conn) == app.redirect_uris
      assert get_flash(conn, :error) == "Failed to authenticate: (error description)."
    end

    test "GET /oauth/registration_details renders registration details form", %{
      app: app,
      conn: conn
    } do
      conn =
        get(
          conn,
          "/oauth/registration_details",
          %{
            "authorization" => %{
              "scopes" => app.scopes,
              "client_id" => app.client_id,
              "redirect_uri" => app.redirect_uris,
              "state" => "a_state",
              "nickname" => nil,
              "email" => "john@doe.com"
            }
          }
        )

      assert response = html_response(conn, 200)
      assert response =~ ~r/name="op" type="submit" value="register"/
      assert response =~ ~r/name="op" type="submit" value="connect"/
    end

    test "with valid params, POST /oauth/register?op=register redirects to `redirect_uri` with `code`",
         %{
           app: app,
           conn: conn
         } do
      registration = insert(:registration, user: nil, info: %{"nickname" => nil, "email" => nil})

      conn =
        conn
        |> put_session(:registration_id, registration.id)
        |> post(
          "/oauth/register",
          %{
            "op" => "register",
            "authorization" => %{
              "scopes" => app.scopes,
              "client_id" => app.client_id,
              "redirect_uri" => app.redirect_uris,
              "state" => "a_state",
              "nickname" => "availablenick",
              "email" => "available@email.com"
            }
          }
        )

      assert response = html_response(conn, 302)
      assert redirected_to(conn) =~ ~r/#{app.redirect_uris}\?code=.+/
    end

    test "with invalid params, POST /oauth/register?op=register renders registration_details page",
         %{
           app: app,
           conn: conn
         } do
      another_user = insert(:user)
      registration = insert(:registration, user: nil, info: %{"nickname" => nil, "email" => nil})

      params = %{
        "op" => "register",
        "authorization" => %{
          "scopes" => app.scopes,
          "client_id" => app.client_id,
          "redirect_uri" => app.redirect_uris,
          "state" => "a_state",
          "nickname" => "availablenickname",
          "email" => "available@email.com"
        }
      }

      for {bad_param, bad_param_value} <-
            [{"nickname", another_user.nickname}, {"email", another_user.email}] do
        bad_registration_attrs = %{
          "authorization" => Map.put(params["authorization"], bad_param, bad_param_value)
        }

        bad_params = Map.merge(params, bad_registration_attrs)

        conn =
          conn
          |> put_session(:registration_id, registration.id)
          |> post("/oauth/register", bad_params)

        assert html_response(conn, 403) =~ ~r/name="op" type="submit" value="register"/
        assert get_flash(conn, :error) == "Error: #{bad_param} has already been taken."
      end
    end

    test "with valid params, POST /oauth/register?op=connect redirects to `redirect_uri` with `code`",
         %{
           app: app,
           conn: conn
         } do
      user = insert(:user, password_hash: Comeonin.Pbkdf2.hashpwsalt("testpassword"))
      registration = insert(:registration, user: nil)

      conn =
        conn
        |> put_session(:registration_id, registration.id)
        |> post(
          "/oauth/register",
          %{
            "op" => "connect",
            "authorization" => %{
              "scopes" => app.scopes,
              "client_id" => app.client_id,
              "redirect_uri" => app.redirect_uris,
              "state" => "a_state",
              "name" => user.nickname,
              "password" => "testpassword"
            }
          }
        )

      assert response = html_response(conn, 302)
      assert redirected_to(conn) =~ ~r/#{app.redirect_uris}\?code=.+/
    end

    test "with invalid params, POST /oauth/register?op=connect renders registration_details page",
         %{
           app: app,
           conn: conn
         } do
      user = insert(:user)
      registration = insert(:registration, user: nil)

      params = %{
        "op" => "connect",
        "authorization" => %{
          "scopes" => app.scopes,
          "client_id" => app.client_id,
          "redirect_uri" => app.redirect_uris,
          "state" => "a_state",
          "name" => user.nickname,
          "password" => "wrong password"
        }
      }

      conn =
        conn
        |> put_session(:registration_id, registration.id)
        |> post("/oauth/register", params)

      assert html_response(conn, 401) =~ ~r/name="op" type="submit" value="connect"/
      assert get_flash(conn, :error) == "Invalid Username/Password"
    end
  end

  describe "GET /oauth/authorize" do
    setup do
      [
        app: insert(:oauth_app, redirect_uris: "https://redirect.url"),
        conn:
          build_conn()
          |> Plug.Session.call(Plug.Session.init(@session_opts))
          |> fetch_session()
      ]
    end

    test "renders authentication page", %{app: app, conn: conn} do
      conn =
        get(
          conn,
          "/oauth/authorize",
          %{
            "response_type" => "code",
            "client_id" => app.client_id,
            "redirect_uri" => app.redirect_uris,
            "scope" => "read"
          }
        )

      assert html_response(conn, 200) =~ ~s(type="submit")
    end

    test "properly handles internal calls with `authorization`-wrapped params", %{
      app: app,
      conn: conn
    } do
      conn =
        get(
          conn,
          "/oauth/authorize",
          %{
            "authorization" => %{
              "response_type" => "code",
              "client_id" => app.client_id,
              "redirect_uri" => app.redirect_uris,
              "scope" => "read"
            }
          }
        )

      assert html_response(conn, 200) =~ ~s(type="submit")
    end

    test "renders authentication page if user is already authenticated but `force_login` is tru-ish",
         %{app: app, conn: conn} do
      token = insert(:oauth_token, app_id: app.id)

      conn =
        conn
        |> put_session(:oauth_token, token.token)
        |> get(
          "/oauth/authorize",
          %{
            "response_type" => "code",
            "client_id" => app.client_id,
            "redirect_uri" => app.redirect_uris,
            "scope" => "read",
            "force_login" => "true"
          }
        )

      assert html_response(conn, 200) =~ ~s(type="submit")
    end

    test "redirects to app if user is already authenticated", %{app: app, conn: conn} do
      token = insert(:oauth_token, app_id: app.id)

      conn =
        conn
        |> put_session(:oauth_token, token.token)
        |> get(
          "/oauth/authorize",
          %{
            "response_type" => "code",
            "client_id" => app.client_id,
            "redirect_uri" => app.redirect_uris,
            "scope" => "read"
          }
        )

      assert redirected_to(conn) == "https://redirect.url"
    end
  end

  describe "POST /oauth/authorize" do
    test "redirects with oauth authorization" do
      user = insert(:user)
      app = insert(:oauth_app, scopes: ["read", "write", "follow"])

      conn =
        build_conn()
        |> post("/oauth/authorize", %{
          "authorization" => %{
            "name" => user.nickname,
            "password" => "test",
            "client_id" => app.client_id,
            "redirect_uri" => app.redirect_uris,
            "scope" => "read write",
            "state" => "statepassed"
          }
        })

      target = redirected_to(conn)
      assert target =~ app.redirect_uris

      query = URI.parse(target).query |> URI.query_decoder() |> Map.new()

      assert %{"state" => "statepassed", "code" => code} = query
      auth = Repo.get_by(Authorization, token: code)
      assert auth
      assert auth.scopes == ["read", "write"]
    end

    test "returns 401 for wrong credentials", %{conn: conn} do
      user = insert(:user)
      app = insert(:oauth_app)

      result =
        conn
        |> post("/oauth/authorize", %{
          "authorization" => %{
            "name" => user.nickname,
            "password" => "wrong",
            "client_id" => app.client_id,
            "redirect_uri" => app.redirect_uris,
            "state" => "statepassed",
            "scope" => Enum.join(app.scopes, " ")
          }
        })
        |> html_response(:unauthorized)

      # Keep the details
      assert result =~ app.client_id
      assert result =~ app.redirect_uris

      # Error message
      assert result =~ "Invalid Username/Password"
    end

    test "returns 401 for missing scopes", %{conn: conn} do
      user = insert(:user)
      app = insert(:oauth_app)

      result =
        conn
        |> post("/oauth/authorize", %{
          "authorization" => %{
            "name" => user.nickname,
            "password" => "test",
            "client_id" => app.client_id,
            "redirect_uri" => app.redirect_uris,
            "state" => "statepassed",
            "scope" => ""
          }
        })
        |> html_response(:unauthorized)

      # Keep the details
      assert result =~ app.client_id
      assert result =~ app.redirect_uris

      # Error message
      assert result =~ "This action is outside the authorized scopes"
    end

    test "returns 401 for scopes beyond app scopes", %{conn: conn} do
      user = insert(:user)
      app = insert(:oauth_app, scopes: ["read", "write"])

      result =
        conn
        |> post("/oauth/authorize", %{
          "authorization" => %{
            "name" => user.nickname,
            "password" => "test",
            "client_id" => app.client_id,
            "redirect_uri" => app.redirect_uris,
            "state" => "statepassed",
            "scope" => "read write follow"
          }
        })
        |> html_response(:unauthorized)

      # Keep the details
      assert result =~ app.client_id
      assert result =~ app.redirect_uris

      # Error message
      assert result =~ "This action is outside the authorized scopes"
    end
  end

  describe "POST /oauth/token" do
    test "issues a token for an all-body request" do
      user = insert(:user)
      app = insert(:oauth_app, scopes: ["read", "write"])

      {:ok, auth} = Authorization.create_authorization(app, user, ["write"])

      conn =
        build_conn()
        |> post("/oauth/token", %{
          "grant_type" => "authorization_code",
          "code" => auth.token,
          "redirect_uri" => app.redirect_uris,
          "client_id" => app.client_id,
          "client_secret" => app.client_secret
        })

      assert %{"access_token" => token, "me" => ap_id} = json_response(conn, 200)

      token = Repo.get_by(Token, token: token)
      assert token
      assert token.scopes == auth.scopes
      assert user.ap_id == ap_id
    end

    test "issues a token for `password` grant_type with valid credentials, with full permissions by default" do
      password = "testpassword"
      user = insert(:user, password_hash: Comeonin.Pbkdf2.hashpwsalt(password))

      app = insert(:oauth_app, scopes: ["read", "write"])

      # Note: "scope" param is intentionally omitted
      conn =
        build_conn()
        |> post("/oauth/token", %{
          "grant_type" => "password",
          "username" => user.nickname,
          "password" => password,
          "client_id" => app.client_id,
          "client_secret" => app.client_secret
        })

      assert %{"access_token" => token} = json_response(conn, 200)

      token = Repo.get_by(Token, token: token)
      assert token
      assert token.scopes == app.scopes
    end

    test "issues a token for request with HTTP basic auth client credentials" do
      user = insert(:user)
      app = insert(:oauth_app, scopes: ["scope1", "scope2", "scope3"])

      {:ok, auth} = Authorization.create_authorization(app, user, ["scope1", "scope2"])
      assert auth.scopes == ["scope1", "scope2"]

      app_encoded =
        (URI.encode_www_form(app.client_id) <> ":" <> URI.encode_www_form(app.client_secret))
        |> Base.encode64()

      conn =
        build_conn()
        |> put_req_header("authorization", "Basic " <> app_encoded)
        |> post("/oauth/token", %{
          "grant_type" => "authorization_code",
          "code" => auth.token,
          "redirect_uri" => app.redirect_uris
        })

      assert %{"access_token" => token, "scope" => scope} = json_response(conn, 200)

      assert scope == "scope1 scope2"

      token = Repo.get_by(Token, token: token)
      assert token
      assert token.scopes == ["scope1", "scope2"]
    end

    test "issue a token for client_credentials grant type" do
      app = insert(:oauth_app, scopes: ["read", "write"])

      conn =
        build_conn()
        |> post("/oauth/token", %{
          "grant_type" => "client_credentials",
          "client_id" => app.client_id,
          "client_secret" => app.client_secret
        })

      assert %{"access_token" => token, "refresh_token" => refresh, "scope" => scope} =
               json_response(conn, 200)

      assert token
      token_from_db = Repo.get_by(Token, token: token)
      assert token_from_db
      assert refresh
      assert scope == "read write"
    end

    test "rejects token exchange with invalid client credentials" do
      user = insert(:user)
      app = insert(:oauth_app)

      {:ok, auth} = Authorization.create_authorization(app, user)

      conn =
        build_conn()
        |> put_req_header("authorization", "Basic JTIxOiVGMCU5RiVBNCVCNwo=")
        |> post("/oauth/token", %{
          "grant_type" => "authorization_code",
          "code" => auth.token,
          "redirect_uri" => app.redirect_uris
        })

      assert resp = json_response(conn, 400)
      assert %{"error" => _} = resp
      refute Map.has_key?(resp, "access_token")
    end

    test "rejects token exchange for valid credentials belonging to unconfirmed user and confirmation is required" do
      setting = Pleroma.Config.get([:instance, :account_activation_required])

      unless setting do
        Pleroma.Config.put([:instance, :account_activation_required], true)
        on_exit(fn -> Pleroma.Config.put([:instance, :account_activation_required], setting) end)
      end

      password = "testpassword"
      user = insert(:user, password_hash: Comeonin.Pbkdf2.hashpwsalt(password))
      info_change = Pleroma.User.Info.confirmation_changeset(user.info, need_confirmation: true)

      {:ok, user} =
        user
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_embed(:info, info_change)
        |> Repo.update()

      refute Pleroma.User.auth_active?(user)

      app = insert(:oauth_app)

      conn =
        build_conn()
        |> post("/oauth/token", %{
          "grant_type" => "password",
          "username" => user.nickname,
          "password" => password,
          "client_id" => app.client_id,
          "client_secret" => app.client_secret
        })

      assert resp = json_response(conn, 403)
      assert %{"error" => _} = resp
      refute Map.has_key?(resp, "access_token")
    end

    test "rejects token exchange for valid credentials belonging to deactivated user" do
      password = "testpassword"

      user =
        insert(:user,
          password_hash: Comeonin.Pbkdf2.hashpwsalt(password),
          info: %{deactivated: true}
        )

      app = insert(:oauth_app)

      conn =
        build_conn()
        |> post("/oauth/token", %{
          "grant_type" => "password",
          "username" => user.nickname,
          "password" => password,
          "client_id" => app.client_id,
          "client_secret" => app.client_secret
        })

      assert resp = json_response(conn, 403)
      assert %{"error" => _} = resp
      refute Map.has_key?(resp, "access_token")
    end

    test "rejects an invalid authorization code" do
      app = insert(:oauth_app)

      conn =
        build_conn()
        |> post("/oauth/token", %{
          "grant_type" => "authorization_code",
          "code" => "Imobviouslyinvalid",
          "redirect_uri" => app.redirect_uris,
          "client_id" => app.client_id,
          "client_secret" => app.client_secret
        })

      assert resp = json_response(conn, 400)
      assert %{"error" => _} = json_response(conn, 400)
      refute Map.has_key?(resp, "access_token")
    end
  end

  describe "POST /oauth/token - refresh token" do
    setup do
      oauth_token_config = Pleroma.Config.get(@oauth_config_path)

      on_exit(fn ->
        Pleroma.Config.get(@oauth_config_path, oauth_token_config)
      end)
    end

    test "issues a new access token with keep fresh token" do
      Pleroma.Config.put(@oauth_config_path, true)
      user = insert(:user)
      app = insert(:oauth_app, scopes: ["read", "write"])

      {:ok, auth} = Authorization.create_authorization(app, user, ["write"])
      {:ok, token} = Token.exchange_token(app, auth)

      response =
        build_conn()
        |> post("/oauth/token", %{
          "grant_type" => "refresh_token",
          "refresh_token" => token.refresh_token,
          "client_id" => app.client_id,
          "client_secret" => app.client_secret
        })
        |> json_response(200)

      ap_id = user.ap_id

      assert match?(
               %{
                 "scope" => "write",
                 "token_type" => "Bearer",
                 "expires_in" => 600,
                 "access_token" => _,
                 "refresh_token" => _,
                 "me" => ^ap_id
               },
               response
             )

      refute Repo.get_by(Token, token: token.token)
      new_token = Repo.get_by(Token, token: response["access_token"])
      assert new_token.refresh_token == token.refresh_token
      assert new_token.scopes == auth.scopes
      assert new_token.user_id == user.id
      assert new_token.app_id == app.id
    end

    test "issues a new access token with new fresh token" do
      Pleroma.Config.put(@oauth_config_path, false)
      user = insert(:user)
      app = insert(:oauth_app, scopes: ["read", "write"])

      {:ok, auth} = Authorization.create_authorization(app, user, ["write"])
      {:ok, token} = Token.exchange_token(app, auth)

      response =
        build_conn()
        |> post("/oauth/token", %{
          "grant_type" => "refresh_token",
          "refresh_token" => token.refresh_token,
          "client_id" => app.client_id,
          "client_secret" => app.client_secret
        })
        |> json_response(200)

      ap_id = user.ap_id

      assert match?(
               %{
                 "scope" => "write",
                 "token_type" => "Bearer",
                 "expires_in" => 600,
                 "access_token" => _,
                 "refresh_token" => _,
                 "me" => ^ap_id
               },
               response
             )

      refute Repo.get_by(Token, token: token.token)
      new_token = Repo.get_by(Token, token: response["access_token"])
      refute new_token.refresh_token == token.refresh_token
      assert new_token.scopes == auth.scopes
      assert new_token.user_id == user.id
      assert new_token.app_id == app.id
    end

    test "returns 400 if we try use access token" do
      user = insert(:user)
      app = insert(:oauth_app, scopes: ["read", "write"])

      {:ok, auth} = Authorization.create_authorization(app, user, ["write"])
      {:ok, token} = Token.exchange_token(app, auth)

      response =
        build_conn()
        |> post("/oauth/token", %{
          "grant_type" => "refresh_token",
          "refresh_token" => token.token,
          "client_id" => app.client_id,
          "client_secret" => app.client_secret
        })
        |> json_response(400)

      assert %{"error" => "Invalid credentials"} == response
    end

    test "returns 400 if refresh_token invalid" do
      app = insert(:oauth_app, scopes: ["read", "write"])

      response =
        build_conn()
        |> post("/oauth/token", %{
          "grant_type" => "refresh_token",
          "refresh_token" => "token.refresh_token",
          "client_id" => app.client_id,
          "client_secret" => app.client_secret
        })
        |> json_response(400)

      assert %{"error" => "Invalid credentials"} == response
    end

    test "issues a new token if token expired" do
      user = insert(:user)
      app = insert(:oauth_app, scopes: ["read", "write"])

      {:ok, auth} = Authorization.create_authorization(app, user, ["write"])
      {:ok, token} = Token.exchange_token(app, auth)

      change =
        Ecto.Changeset.change(
          token,
          %{valid_until: NaiveDateTime.add(NaiveDateTime.utc_now(), -86_400 * 30)}
        )

      {:ok, access_token} = Repo.update(change)

      response =
        build_conn()
        |> post("/oauth/token", %{
          "grant_type" => "refresh_token",
          "refresh_token" => access_token.refresh_token,
          "client_id" => app.client_id,
          "client_secret" => app.client_secret
        })
        |> json_response(200)

      ap_id = user.ap_id

      assert match?(
               %{
                 "scope" => "write",
                 "token_type" => "Bearer",
                 "expires_in" => 600,
                 "access_token" => _,
                 "refresh_token" => _,
                 "me" => ^ap_id
               },
               response
             )

      refute Repo.get_by(Token, token: token.token)
      token = Repo.get_by(Token, token: response["access_token"])
      assert token
      assert token.scopes == auth.scopes
      assert token.user_id == user.id
      assert token.app_id == app.id
    end
  end

  describe "POST /oauth/token - bad request" do
    test "returns 500" do
      response =
        build_conn()
        |> post("/oauth/token", %{})
        |> json_response(500)

      assert %{"error" => "Bad request"} == response
    end
  end

  describe "POST /oauth/revoke - bad request" do
    test "returns 500" do
      response =
        build_conn()
        |> post("/oauth/revoke", %{})
        |> json_response(500)

      assert %{"error" => "Bad request"} == response
    end
  end
end
