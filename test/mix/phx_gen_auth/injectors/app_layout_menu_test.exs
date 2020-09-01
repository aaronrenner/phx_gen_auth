defmodule Mix.Phx.Gen.Auth.Injectors.AppLayoutMenuTest do
  use ExUnit.Case, async: true

  alias Mix.Phoenix.Schema
  alias Mix.Phx.Gen.Auth.Injectors.AppLayoutMenu

  describe "inject/2" do
    test "injects render user_menu.html at the bottom of nav section when it exists" do
      schema = Schema.new("Accounts.User", "users", [], [])

      input = """
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <title>Demo · Phoenix Framework</title>
        </head>
        <body>
          <header>
            <section class="container">
              <nav role="navigation">
                <ul>
                  <li><a href="https://hexdocs.pm/phoenix/overview.html">Get Started</a></li>
                  <%= if function_exported?(Routes, :live_dashboard_path, 2) do %>
                    <li><%= link "LiveDashboard", to: Routes.live_dashboard_path(@conn, :home) %></li>
                  <% end %>
                </ul>
              </nav>
            </section>
          </header>
        </body>
      </html>
      """

      {:ok, injected} = AppLayoutMenu.inject(input, schema)

      assert injected ==
               """
               <!DOCTYPE html>
               <html lang="en">
                 <head>
                   <title>Demo · Phoenix Framework</title>
                 </head>
                 <body>
                   <header>
                     <section class="container">
                       <nav role="navigation">
                         <ul>
                           <li><a href="https://hexdocs.pm/phoenix/overview.html">Get Started</a></li>
                           <%= if function_exported?(Routes, :live_dashboard_path, 2) do %>
                             <li><%= link "LiveDashboard", to: Routes.live_dashboard_path(@conn, :home) %></li>
                           <% end %>
                         </ul>
                         <%= render "_user_menu.html", assigns %>
                       </nav>
                     </section>
                   </header>
                 </body>
               </html>
               """
    end

    test "injects render user_menu.html at the bottom of nav section when it exists with windows line endings" do
      schema = Schema.new("Accounts.User", "users", [], [])

      input = """
      <!DOCTYPE html>\r
      <html lang="en">\r
        <head>\r
          <title>Demo · Phoenix Framework</title>\r
        </head>\r
        <body>\r
          <header>\r
            <section class="container">\r
              <nav role="navigation">\r
                <ul>\r
                  <li><a href="https://hexdocs.pm/phoenix/overview.html">Get Started</a></li>\r
                  <%= if function_exported?(Routes, :live_dashboard_path, 2) do %>\r
                    <li><%= link "LiveDashboard", to: Routes.live_dashboard_path(@conn, :home) %></li>\r
                  <% end %>\r
                </ul>\r
              </nav>\r
            </section>\r
          </header>\r
        </body>\r
      </html>\r
      """

      {:ok, injected} = AppLayoutMenu.inject(input, schema)

      assert injected ==
               """
               <!DOCTYPE html>\r
               <html lang="en">\r
                 <head>\r
                   <title>Demo · Phoenix Framework</title>\r
                 </head>\r
                 <body>\r
                   <header>\r
                     <section class="container">\r
                       <nav role="navigation">\r
                         <ul>\r
                           <li><a href="https://hexdocs.pm/phoenix/overview.html">Get Started</a></li>\r
                           <%= if function_exported?(Routes, :live_dashboard_path, 2) do %>\r
                             <li><%= link "LiveDashboard", to: Routes.live_dashboard_path(@conn, :home) %></li>\r
                           <% end %>\r
                         </ul>\r
                         <%= render "_user_menu.html", assigns %>\r
                       </nav>\r
                     </section>\r
                   </header>\r
                 </body>\r
               </html>\r
               """
    end

    test "injects render user_menu.html after the opening body tag" do
      schema = Schema.new("Accounts.User", "users", [], [])

      input = """
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <title>Demo · Phoenix Framework</title>
        </head>
        <body>
          <main role="main" class="container">
            <p class="alert alert-info" role="alert"><%= get_flash(@conn, :info) %></p>
            <p class="alert alert-danger" role="alert"><%= get_flash(@conn, :error) %></p>
            <%= @inner_content %>
          </main>
        </body>
      </html>
      """

      {:ok, injected} = AppLayoutMenu.inject(input, schema)

      assert injected ==
               """
               <!DOCTYPE html>
               <html lang="en">
                 <head>
                   <title>Demo · Phoenix Framework</title>
                 </head>
                 <body>
                   <%= render "_user_menu.html", assigns %>
                   <main role="main" class="container">
                     <p class="alert alert-info" role="alert"><%= get_flash(@conn, :info) %></p>
                     <p class="alert alert-danger" role="alert"><%= get_flash(@conn, :error) %></p>
                     <%= @inner_content %>
                   </main>
                 </body>
               </html>
               """
    end

    test "works with windows line endings" do
      schema = Schema.new("Accounts.User", "users", [], [])

      input = """
      <!DOCTYPE html>\r
      <html lang="en">\r
        <head>\r
          <title>Demo · Phoenix Framework</title>\r
        </head>\r
        <body>\r
          <main role="main" class="container">\r
            <p class="alert alert-info" role="alert"><%= get_flash(@conn, :info) %></p>\r
            <p class="alert alert-danger" role="alert"><%= get_flash(@conn, :error) %></p>\r
            <%= @inner_content %>\r
          </main>\r
        </body>\r
      </html>\r
      """

      {:ok, injected} = AppLayoutMenu.inject(input, schema)

      assert injected ==
               """
               <!DOCTYPE html>\r
               <html lang="en">\r
                 <head>\r
                   <title>Demo · Phoenix Framework</title>\r
                 </head>\r
                 <body>\r
                   <%= render "_user_menu.html", assigns %>\r
                   <main role="main" class="container">\r
                     <p class="alert alert-info" role="alert"><%= get_flash(@conn, :info) %></p>\r
                     <p class="alert alert-danger" role="alert"><%= get_flash(@conn, :error) %></p>\r
                     <%= @inner_content %>\r
                   </main>\r
                 </body>\r
               </html>\r
               """
    end

    test "returns :already_injected when render is already found in file" do
      schema = Schema.new("Accounts.User", "users", [], [])

      input = """
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <title>Demo · Phoenix Framework</title>
        </head>
        <body>
          <div class="my-header">
            <%= render "_user_menu.html", assigns %>
          </div>
          <main role="main" class="container">
            <p class="alert alert-info" role="alert"><%= get_flash(@conn, :info) %></p>
            <p class="alert alert-danger" role="alert"><%= get_flash(@conn, :error) %></p>
            <%= @inner_content %>
          </main>
        </body>
      </html>
      """

      assert :already_injected = AppLayoutMenu.inject(input, schema)
    end

    test "returns {:error, :unable_to_inject} when the body tag isn't found" do
      schema = Schema.new("Accounts.User", "users", [], [])

      input = ""

      assert {:error, :unable_to_inject} = AppLayoutMenu.inject(input, schema)
    end
  end

  describe "help_text/2" do
    test "returns a string with the expected help text" do
      schema = Schema.new("Accounts.User", "users", [], [])

      file_path = Path.expand("foo.ex")

      assert AppLayoutMenu.help_text(file_path, schema) ==
               """
               Add a render call for "_user_menu.html" to foo.ex:

                 <nav role="navigation">
                   <%= render "_user_menu.html", assigns %>
                 </nav>
               """
    end
  end
end
