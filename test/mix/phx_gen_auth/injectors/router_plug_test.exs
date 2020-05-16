defmodule Mix.Phx.Gen.Auth.Injectors.RouterPlugTest do
  use ExUnit.Case, async: true

  alias Mix.Phoenix.{Context, Schema}
  alias Mix.Phx.Gen.Auth.Injectors.RouterPlug

  describe "inject/2" do
    test "injects after :put_secure_browser_headers" do
      schema = Schema.new("Accounts.User", "users", [], [])
      context = Context.new("Accounts", schema, [])

      input = """
      defmodule DemoWeb.Router do
        use DemoWeb, :router

        pipeline :browser do
          plug :accepts, ["html"]
          plug :fetch_session
          plug :fetch_flash
          plug :protect_from_forgery
          plug :put_secure_browser_headers
        end
      end
      """

      {:ok, injected} = RouterPlug.inject(input, context)

      assert injected ==
               """
               defmodule DemoWeb.Router do
                 use DemoWeb, :router

                 pipeline :browser do
                   plug :accepts, ["html"]
                   plug :fetch_session
                   plug :fetch_flash
                   plug :protect_from_forgery
                   plug :put_secure_browser_headers
                   plug :fetch_current_user
                 end
               end
               """
    end

    test "injects after :put_secure_browser_headers even when it has additional options" do
      schema = Schema.new("Accounts.User", "users", [], [])
      context = Context.new("Accounts", schema, [])

      input = """
      defmodule DemoWeb.Router do
        use DemoWeb, :router

        pipeline :browser do
          plug :accepts, ["html"]
          plug :fetch_session
          plug :fetch_flash
          plug :protect_from_forgery
          plug :put_secure_browser_headers, %{"content-security-policy" => @csp}
        end
      end
      """

      {:ok, injected} = RouterPlug.inject(input, context)

      assert injected ==
               """
               defmodule DemoWeb.Router do
                 use DemoWeb, :router

                 pipeline :browser do
                   plug :accepts, ["html"]
                   plug :fetch_session
                   plug :fetch_flash
                   plug :protect_from_forgery
                   plug :put_secure_browser_headers, %{"content-security-policy" => @csp}
                   plug :fetch_current_user
                 end
               end
               """
    end

    test "errors when :put_secure_browser_headers_is_missing" do
      schema = Schema.new("Accounts.User", "users", [], [])
      context = Context.new("Accounts", schema, [])

      input = """
      defmodule DemoWeb.Router do
        use DemoWeb, :router

        pipeline :browser do
          plug :accepts, ["html"]
          plug :fetch_session
          plug :fetch_flash
          plug :protect_from_forgery
        end
      end
      """

      assert {:error, :unable_to_inject} = RouterPlug.inject(input, context)
    end
  end

  describe "help_text/2" do
    test "returns a string with the expected help text" do
      schema = Schema.new("Accounts.User", "users", [], [])
      context = Context.new("Accounts", schema, [])

      file_path = Path.expand("foo.ex")

      assert RouterPlug.help_text(file_path, context) ==
               """
               Add the :fetch_current_user plug to the :browser pipeline in foo.ex:

                   pipeline :browser do
                     ...
                     plug :put_secure_browser_headers
                     plug :fetch_current_user
                   end
               """
    end
  end
end
