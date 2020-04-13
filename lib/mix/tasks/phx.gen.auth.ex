defmodule Mix.Tasks.Phx.Gen.Auth do
  @shortdoc "Generates authentication logic for a resource"

  @moduledoc """
  Generates authentication logic for a resource

      mix phx.gen.auth Accounts User users

  ## Web namespace

  By default, the controllers and view will be namespaced by the schema name.
  You can customize the web module namespace by passing the `--web` flag with a
  module name, for example:

      mix phx.gen.auth Accounts User users --web Warehouse

  Which would generate the controllers, views, templates and associated tests in nested in the `MyAppWeb.Warehouse` namespace:

  * `lib/my_app_web/controllers/warehouse/user_auth.ex`
  * `lib/my_app_web/controllers/warehouse/user_confirmation_controller.ex`
  * `lib/my_app_web/views/warehouse/user_confirmation_view.ex`
  * `lib/my_app_web/templates/warehouse/user_confirmation/new.html.eex`
  * `test/my_app_web/controllers/warehouse/user_auth_test.exs`
  * `test/my_app_web/controllers/warehouse/user_confirmation_controller_test.exs`
  * and so on...

  ## Notes about the generated authentication system

  ### Password hashing

  The password hashing mechanism defaults to `bcrypt` for
  Unix systems and `pdkdf2` for Windows systems. Both
  systems use [the Comeonin interface](https://hexdocs.pm/comeonin/).

  ### Forbidding access

  The generated code ships with an auth module with handful
  plugs that fetch the current account, requires authentication
  and so on. For instance, for an app named Demo which invoked
  `mix phx.gen.auth Accounts User users`, you will find a module
  named `DemoWeb.UserAuth` with plugs such as:

    * `fetch_current_user` - fetches the current user information if
      available

    * `require_authenticated_user` - must be invoked after
      `fetch_current_user` and requires that a current exists and is
      authenticated

    * `redirect_if_user_is_not_authenticated` - used for the few
      pages that must not be available to authenticated users

  ### Confirmation

  The generated functionality ships with an account confirmation
  mechanism, where users have to confirm their account, typically
  by e-mail. However, the generated code does not forbid users
  from using the application if their accounts have not yet been
  confirmed. You can trivially add this functionality by customizing
  the plugs generated in the Auth module.

  ### Notifiers

  The generated code is not integrated with any system to send
  SMSs or e-mails for confirming accounts, reseting passwords,
  etc. Instead it simply logs a message to the terminal. It is
  your responsibility to integrate with the proper system after
  generation.

  ### Tracking sessions

  All sessions and tokens are tracked in a separate table. This
  allows you to track how many sessions are active for each account.
  You could even expose this information to users if desired.

  Note that whenever the password changes (either via reset password
  or directly), all tokens are deleted and the user has to login
  again on all devices.

  ### Enumeration attacks

  An enumeration attack allows an attacker to enumerate all e-mails
  registered in the application. The generated authentication code
  protect against enumeration attacks on all endpoints, except in
  the registration and update e-mail forms. If your application is
  really sensitive to enumeration attacks, you need to implement
  your own registration workflow, which tends to be very different
  from the workflow for most applications.

  ### Case sensitiveness

  The e-mail lookup is made to be case insensitive. Case insensitive
  lookups are the default in MySQL and MSSQL but require the
  citext extension in Postgres.

  ### Concurrent tests

  The generated tests run concurrently if you are using a database
  that supports concurrent tests (Postgres).
  """

  use Mix.Task

  alias Mix.Phoenix.{Context, Schema}
  alias Mix.Tasks.Phx.Gen
  alias Mix.Phx.Gen.Auth.{Injector, Migration}

  @switches [web: :string]

  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix phx.gen.auth can only be run inside an application directory")
    end

    {opts, parsed} = OptionParser.parse!(args, strict: @switches)
    validate_args!(parsed)

    context_args = OptionParser.to_argv(opts, switches: @switches) ++ parsed

    {context, schema} = Gen.Context.build(context_args, __MODULE__)
    Gen.Context.prompt_for_code_injection(context)

    # Needed so we can get the ecto adapter and ensure other
    # libraries are loaded.
    #
    # As far as I can tell, everything after this must be tested with an
    # integration test.
    Mix.Task.run("compile")

    validate_required_dependencies!()

    ecto_adapter = get_ecto_adapter!(schema)
    migration = Migration.build(ecto_adapter)

    binding = [
      context: context,
      schema: schema,
      migration: migration,
      endpoint_module: Module.concat([context.web_module, Endpoint]),
      auth_module: Module.concat([context.web_module, schema.web_namespace, "#{inspect(schema.alias)}Auth"]),
      router_scope: router_scope(context),
      web_path_prefix: web_path_prefix(schema),
      test_case_options: test_case_options(ecto_adapter)
    ]

    paths = generator_paths()

    prompt_for_conflicts(context)

    context
    |> copy_new_files(binding, paths)
    |> inject_conn_case_helpers(paths, binding)
    |> inject_routes(paths, binding)
    |> inject_config()
    |> maybe_inject_mix_dependency()
    |> maybe_inject_router_import(binding)
    |> maybe_inject_router_plug(binding)
    |> maybe_inject_app_layout_menu(binding)
    |> print_shell_instructions()
  end

  defp validate_args!([_, _, _]), do: :ok

  defp validate_args!(_) do
    raise_with_help("Invalid arguments")
  end

  defp validate_required_dependencies! do
    unless Code.ensure_loaded?(Ecto.Adapters.SQL) do
      raise_with_help("mix phx.gen.auth requires ecto_sql", :phx_generator_args)
    end
  end

  defp prompt_for_conflicts(context) do
    context
    |> files_to_be_generated()
    |> Mix.Phoenix.prompt_for_conflicts()
  end

  defp files_to_be_generated(%Context{schema: schema, context_app: context_app} = context) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    web_test_prefix = Mix.Phoenix.web_test_path(context_app)
    migrations_prefix = Mix.Phoenix.context_app_path(context_app, "priv/repo/migrations")
    web_path = to_string(schema.web_path)
    context_app_prefix = Mix.Phoenix.context_app_path(context_app, "")

    [
      {:eex, "context_fixtures.ex", Path.join([context_app_prefix, "test", "support", "fixtures", "#{context.basename}_fixtures.ex"])},
      {:eex, "migration.ex", Path.join([migrations_prefix, "#{timestamp()}_create_#{schema.singular}_auth_tables.exs"])},
      {:eex, "notifier.ex", Path.join([context.dir, "#{schema.singular}_notifier.ex"])},
      {:eex, "schema.ex", Path.join([context.dir, "#{schema.singular}.ex"])},
      {:eex, "schema_token.ex", Path.join([context.dir, "#{schema.singular}_token.ex"])},
      {:eex, "auth.ex", Path.join([web_prefix, "controllers", web_path, "#{schema.singular}_auth.ex"])},
      {:eex, "auth_test.exs", Path.join([web_test_prefix, "controllers", web_path, "#{schema.singular}_auth_test.exs"])},
      {:eex, "confirmation_view.ex", Path.join([web_prefix, "views", web_path, "#{schema.singular}_confirmation_view.ex"])},
      {:eex, "confirmation_new.html.eex", Path.join([web_prefix, "templates", web_path, "#{schema.singular}_confirmation", "new.html.eex"])},
      {:eex, "confirmation_controller.ex", Path.join([web_prefix, "controllers", web_path, "#{schema.singular}_confirmation_controller.ex"])},
      {:eex, "confirmation_controller_test.exs", Path.join([web_test_prefix, "controllers", web_path, "#{schema.singular}_confirmation_controller_test.exs"])},
      {:eex, "_menu.html.eex", Path.join([web_prefix, "templates", "layout", "_#{schema.singular}_menu.html.eex"])},
      {:eex, "registration_new.html.eex", Path.join([web_prefix, "templates", web_path, "#{schema.singular}_registration", "new.html.eex"])},
      {:eex, "registration_controller.ex", Path.join([web_prefix, "controllers", web_path, "#{schema.singular}_registration_controller.ex"])},
      {:eex, "registration_controller_test.exs", Path.join([web_test_prefix, "controllers", web_path, "#{schema.singular}_registration_controller_test.exs"])},
      {:eex, "registration_view.ex", Path.join([web_prefix, "views", web_path, "#{schema.singular}_registration_view.ex"])},
      {:eex, "reset_password_view.ex", Path.join([web_prefix, "views", web_path, "#{schema.singular}_reset_password_view.ex"])},
      {:eex, "reset_password_controller.ex", Path.join([web_prefix, "controllers", web_path, "#{schema.singular}_reset_password_controller.ex"])},
      {:eex, "reset_password_controller_test.exs",
       Path.join([web_test_prefix, "controllers", web_path, "#{schema.singular}_reset_password_controller_test.exs"])},
      {:eex, "reset_password_edit.html.eex", Path.join([web_prefix, "templates", web_path, "#{schema.singular}_reset_password", "edit.html.eex"])},
      {:eex, "reset_password_new.html.eex", Path.join([web_prefix, "templates", web_path, "#{schema.singular}_reset_password", "new.html.eex"])},
      {:eex, "session_view.ex", Path.join([web_prefix, "views", web_path, "#{schema.singular}_session_view.ex"])},
      {:eex, "session_controller.ex", Path.join([web_prefix, "controllers", web_path, "#{schema.singular}_session_controller.ex"])},
      {:eex, "session_controller_test.exs", Path.join([web_test_prefix, "controllers", web_path, "#{schema.singular}_session_controller_test.exs"])},
      {:eex, "session_new.html.eex", Path.join([web_prefix, "templates", web_path, "#{schema.singular}_session", "new.html.eex"])},
      {:eex, "settings_view.ex", Path.join([web_prefix, "views", web_path, "#{schema.singular}_settings_view.ex"])},
      {:eex, "settings_edit.html.eex", Path.join([web_prefix, "templates", web_path, "#{schema.singular}_settings", "edit.html.eex"])},
      {:eex, "settings_controller.ex", Path.join([web_prefix, "controllers", web_path, "#{schema.singular}_settings_controller.ex"])},
      {:eex, "settings_controller_test.exs", Path.join([web_test_prefix, "controllers", web_path, "#{schema.singular}_settings_controller_test.exs"])}
    ]
  end

  defp copy_new_files(%Context{} = context, binding, paths) do
    files = files_to_be_generated(context)
    Mix.Phoenix.copy_from(paths, "priv/templates/phx.gen.auth", binding, files)
    inject_context_functions(context, paths, binding)
    inject_tests(context, paths, binding)

    context
  end

  defp inject_context_functions(%Context{file: file} = context, paths, binding) do
    unless Context.pre_existing?(context) do
      Mix.Generator.create_file(file, Mix.Phoenix.eval_from(paths, "priv/templates/phx.gen.context/context.ex", binding))
    end

    paths
    |> Mix.Phoenix.eval_from("priv/templates/phx.gen.auth/context_functions.ex", binding)
    |> inject_before_final_end(file)
  end

  defp inject_tests(%Context{test_file: test_file} = context, paths, binding) do
    unless Context.pre_existing_tests?(context) do
      Mix.Generator.create_file(test_file, Mix.Phoenix.eval_from(paths, "priv/templates/phx.gen.context/context_test.exs", binding))
    end

    paths
    |> Mix.Phoenix.eval_from("priv/templates/phx.gen.auth/test_cases.exs", binding)
    |> inject_before_final_end(test_file)
  end

  defp inject_conn_case_helpers(%Context{} = context, paths, binding) do
    # TODO: Figure out what happens if this file isn't here
    test_file = "test/support/conn_case.ex"

    paths
    |> Mix.Phoenix.eval_from("priv/templates/phx.gen.auth/conn_case.exs", binding)
    |> inject_before_final_end(test_file)

    context
  end

  defp inject_routes(%Context{context_app: ctx_app} = context, paths, binding) do
    # TODO: Figure out what happens if this file isn't here
    web_prefix = Mix.Phoenix.web_path(ctx_app)
    file_path = Path.join(web_prefix, "router.ex")

    paths
    |> Mix.Phoenix.eval_from("priv/templates/phx.gen.auth/routes.ex", binding)
    |> inject_before_final_end(file_path)

    context
  end

  defp maybe_inject_mix_dependency(%Context{context_app: ctx_app} = context) do
    # TODO: Figure out what happens if this file isn't here
    # TODO: Figure out how to make this show up in the right place in test
    file_path = Mix.Phoenix.context_app_path(ctx_app, "mix.exs")

    file = File.read!(file_path)
    inject = "{:bcrypt_elixir, \"~> 2.0\"}"

    case Injector.inject_mix_dependency(file, inject) do
      {:ok, new_file} ->
        Mix.shell().info([:green, "* injecting ", :reset, Path.relative_to_cwd(file_path)])
        File.write!(file_path, new_file)

      :already_injected ->
        :ok

      {:error, :unable_to_inject} ->
        Mix.shell().info("""

        Add your #{inspect(inject)} dependency to #{file_path}:

            defp deps do
              [
                #{inject},
                ...
              ]
            end
        """)
    end

    context
  end

  defp maybe_inject_router_import(%Context{context_app: ctx_app} = context, binding) do
    # TODO: Figure out what happens if this file isn't here
    web_prefix = Mix.Phoenix.web_path(ctx_app)
    file_path = Path.join(web_prefix, "router.ex")
    file = File.read!(file_path)
    auth_module = Keyword.fetch!(binding, :auth_module)
    inject = "import #{inspect(auth_module)}"

    if String.contains?(file, inject) do
      :ok
    else
      do_inject_router_import(context, file, file_path, auth_module, inject)
    end

    context
  end

  defp do_inject_router_import(context, file, file_path, auth_module, inject) do
    Mix.shell().info([:green, "* injecting ", :reset, Path.relative_to_cwd(file_path), " (imports)"])

    use_line = "use #{inspect(context.web_module)}, :router"

    new_file = String.replace(file, use_line, "#{use_line}\n\n  #{inject}")

    if file != new_file do
      File.write!(file_path, new_file)
    else
      Mix.shell().info("""

      Add your #{inspect(auth_module)} import to #{file_path}:

          defmodule #{inspect(context.web_module)}.Router do
            #{use_line}

            # Import authentication plugs
            #{inject}

            ...
          end
      """)
    end
  end

  defp maybe_inject_router_plug(%Context{context_app: ctx_app} = context, binding) do
    # TODO: Figure out what happens if this file isn't here
    web_prefix = Mix.Phoenix.web_path(ctx_app)
    file_path = Path.join(web_prefix, "router.ex")
    file = File.read!(file_path)
    schema = Keyword.fetch!(binding, :schema)
    plug_name = ":fetch_current_#{schema.singular}"
    inject = "plug #{plug_name}"

    if String.contains?(file, inject) do
      :ok
    else
      do_inject_router_plug(context, file, file_path, plug_name, inject)
    end

    context
  end

  defp do_inject_router_plug(_context, file, file_path, plug_name, inject) do
    Mix.shell().info([:green, "* injecting ", :reset, Path.relative_to_cwd(file_path), " (plug)"])

    anchor_line = "plug :put_secure_browser_headers"

    new_file = String.replace(file, anchor_line, "#{anchor_line}\n    #{inject}")

    if file != new_file do
      File.write!(file_path, new_file)
    else
      Mix.shell().info("""

      Add the #{plug_name} plug to the browser pipeline in #{file_path}:

        pipeline :browser do
          ...
          #{anchor_line}
          #{inject}
        end

        ...
      end
      """)
    end
  end

  defp maybe_inject_app_layout_menu(%Context{context_app: ctx_app} = context, binding) do
    # TODO: Figure out what happens if this file isn't here
    web_prefix = Mix.Phoenix.web_path(ctx_app)
    file_path = Path.join([web_prefix, "templates", "layout", "app.html.eex"])
    file = File.read!(file_path)
    schema = Keyword.fetch!(binding, :schema)
    menu_name = "_#{schema.singular}_menu.html"
    inject = "<%= render \"#{menu_name}\", assigns %>"

    if String.contains?(file, inject) do
      :ok
    else
      do_inject_app_layout_menu(context, file, file_path, menu_name, inject)
    end

    context
  end

  defp do_inject_app_layout_menu(_context, file, file_path, menu_name, inject) do
    Mix.shell().info([:green, "* injecting ", :reset, Path.relative_to_cwd(file_path)])

    # This matches all characters that have a preceding
    # <nav role="navigation"> and a trailing </nav>
    # (Positive look ahead and positive look behind).
    new_file =
      Regex.replace(
        ~r|(?<=<nav role="navigation">).*(?=</nav>)|s,
        file,
        "\n          #{inject}\n        "
      )

    if file != new_file do
      File.write!(file_path, new_file)
    else
      Mix.shell().info("""

      Add a render call for #{inspect(menu_name)} to #{file_path}:

        <nav role="navigation">
          #{inject}
        </nav>
      """)
    end
  end

  defp inject_config(context) do
    project_path =
      if Mix.Phoenix.in_umbrella?(File.cwd!()) do
        Path.expand("../../")
      else
        File.cwd!()
      end

    config_inject(project_path, "config/test.exs", """
    # Only in tests, remove the complexity from the password encryption algorithm
    config :bcrypt_elixir, :log_rounds, 1
    """)

    context
  end

  defp config_inject(path, file, to_inject) do
    file = Path.join(path, file)

    contents =
      case File.read(file) do
        {:ok, bin} -> bin
        {:error, _} -> "use Mix.Config\n"
      end

    with :error <- split_with_self(contents, "use Mix.Config\n"),
         :error <- split_with_self(contents, "import Config\n") do
      Mix.raise(~s[Could not find "use Mix.Config" or "import Config" in #{inspect(file)}])
    else
      [left, middle, right] ->
        File.write!(file, [left, middle, ?\n, String.trim(to_inject), ?\n, right])
    end
  end

  defp split_with_self(contents, text) do
    case :binary.split(contents, text) do
      [left, right] -> [left, text, right]
      [_] -> :error
    end
  end

  defp print_shell_instructions(%Context{} = context) do
    Mix.shell().info("""

    Please re-fetch your dependencies with the following command:

        mix deps.get
    """)

    Mix.shell().info("""

    Remember to update your repository by running migrations:

      $ mix ecto.migrate
    """)

    context
  end

  defp router_scope(%Context{schema: schema} = context) do
    prefix = Module.concat(context.web_module, schema.web_namespace)

    if schema.web_namespace do
      ~s|"/#{schema.web_path}", #{inspect(prefix)}, as: :#{schema.web_path}|
    else
      ~s|"/", #{inspect(context.web_module)}|
    end
  end

  defp web_path_prefix(%Schema{web_path: nil}), do: ""
  defp web_path_prefix(%Schema{web_path: web_path}), do: "/" <> web_path

  # The paths to look for template files for generators.
  #
  # Defaults to checking the current app's `priv` directory,
  # and falls back to phx_gen_auth's `priv` directory.
  defp generator_paths do
    [".", :phx_gen_auth, :phoenix]
  end

  defp inject_before_final_end(content_to_inject, file_path) do
    file = File.read!(file_path)

    case Injector.inject_before_final_end(file, content_to_inject) do
      {:ok, new_file} ->
        Mix.shell().info([:green, "* injecting ", :reset, Path.relative_to_cwd(file_path)])
        File.write!(file_path, new_file)

      :already_injected ->
        :ok
    end
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)

  defp get_ecto_adapter!(%Schema{repo: repo}) do
    if Code.ensure_loaded?(repo) do
      repo.__adapter__()
    else
      Mix.raise("Unable to find #{inspect(repo)}")
    end
  end

  def raise_with_help(msg) do
    raise_with_help(msg, :general)
  end

  defp raise_with_help(msg, :general) do
    Mix.raise("""
    #{msg}

    mix phx.gen.auth expects a context module name, followed by
    the schema module and its plural name (used as the schema
    table name).

    For example:

    mix phx.gen.auth Accounts User users

    The context serves as the API boundary for the given resource.
    Multiple resources may belong to a context and a resource may be
    split over distinct contexts (such as Accounts.User and Payments.User).
    """)
  end

  defp raise_with_help(msg, :phx_generator_args) do
    Mix.raise("""
    #{msg}

    mix phx.gen.auth must be installed into a Phoenix 1.5 app that
    contains ecto and html templates.

    mix phx.new my_app
    mix phx.new my_app --umbrella
    mix phx.new my_app --database mysql

    Apps generated with --no-ecto and --no-html are not supported
    """)
  end

  defp test_case_options(Ecto.Adapters.Postgres), do: ", async: true"
  defp test_case_options(adapter) when is_atom(adapter), do: ""
end
