defmodule <%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>SessionControllerTest do
  use <%= inspect context.web_module %>.ConnCase<%= test_case_options %>

  import <%= inspect context.module %>Fixtures

  setup do
    %{<%= schema.singular %>: <%= schema.singular %>_fixture()}
  end

  describe "GET <%= web_path_prefix %>/<%= schema.plural %>/login" do
    test "renders login page", %{conn: conn} do
      conn = get(conn, Routes.<%= schema.route_helper %>_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Login</h1>"
      assert response =~ "Login</a>"
      assert response =~ "Register</a>"
    end

    test "redirects if already logged in", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn = conn |> login_<%= schema.singular %>(<%= schema.singular %>) |> get(Routes.<%= schema.route_helper %>_session_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST <%= web_path_prefix %>/<%= schema.plural %>/login" do
    test "logs the <%= schema.singular %> in", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn =
        post(conn, Routes.<%= schema.route_helper %>_session_path(conn, :create), %{
          "<%= schema.singular %>" => %{"email" => <%= schema.singular %>.email, "password" => valid_<%= schema.singular %>_password()}
        })

      assert get_session(conn, :<%= schema.singular %>_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ <%= schema.singular %>.email
      assert response =~ "Settings</a>"
      assert response =~ "Logout</a>"
    end

    test "logs the <%= schema.singular %> in with remember me", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn =
        post(conn, Routes.<%= schema.route_helper %>_session_path(conn, :create), %{
          "<%= schema.singular %>" => %{
            "email" => <%= schema.singular %>.email,
            "password" => valid_<%= schema.singular %>_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["<%= schema.singular %>_remember_me"]
      assert redirected_to(conn) =~ "/"
    end

    test "emits error message with invalid credentials", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn =
        post(conn, Routes.<%= schema.route_helper %>_session_path(conn, :create), %{
          "<%= schema.singular %>" => %{"email" => <%= schema.singular %>.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Login</h1>"
      assert response =~ "Invalid e-mail or password"
    end
  end

  describe "DELETE <%= web_path_prefix %>/<%= schema.plural %>/logout" do
    test "logs the <%= schema.singular %> out", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn = conn |> login_<%= schema.singular %>(<%= schema.singular %>) |> delete(Routes.<%= schema.route_helper %>_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :<%= schema.singular %>_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the <%= schema.singular %> is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.<%= schema.route_helper %>_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :<%= schema.singular %>_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end
