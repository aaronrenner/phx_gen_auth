defmodule Mix.Tasks.Phx.Gen.Auth do
  @shortdoc "Generates authentication logic for a resource"

  @moduledoc """
  Generates authentication logic for a resource

    mix phx.gen.auth Accounts User users
  """

  use Mix.Task

  alias Mix.Phoenix.{Context}
  alias Mix.Tasks.Phx.Gen

  @doc false
  def run(args) do
    {context, schema} = Gen.Context.build(args)
    Gen.Context.prompt_for_code_injection(context)

    binding = [context: context, schema: schema]
    paths = generator_paths()

    prompt_for_conflicts(context)

    context
    |> copy_new_files(binding, paths)
    |> inject_conn_case_helpers(paths, binding)
    |> print_shell_instructions()
  end

  defp prompt_for_conflicts(context) do
    context
    |> files_to_be_generated()
    |> Mix.Phoenix.prompt_for_conflicts()
  end

  defp files_to_be_generated(%Context{schema: schema, context_app: context_app} = context) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    web_path = to_string(schema.web_path)

    [
      {:eex, "context.ex", context.file},
      {:eex, "context_test.exs", context.test_file},
      {:eex, "context_fixtures.ex", Path.join(["test", "support", "fixtures", "#{context.basename}_fixtures.ex"])},
      {:eex, "migration.ex", Path.join(["priv", "repo", "migrations", "#{timestamp()}_create_auth_tables.exs"])},
      {:eex, "notifier.ex", Path.join([context.dir, "#{schema.singular}_notifier.ex"])},
      {:eex, "schema.ex", Path.join([context.dir, "#{schema.singular}.ex"])},
      {:eex, "schema_token.ex", Path.join([context.dir, "#{schema.singular}_token.ex"])},
      {:eex, "confirmation_view.ex", Path.join([web_prefix, "views", web_path, "#{schema.singular}_confirmation_view.ex"])},
      {:eex, "registration_view.ex", Path.join([web_prefix, "views", web_path, "#{schema.singular}_registration_view.ex"])},
      {:eex, "reset_password_view.ex", Path.join([web_prefix, "views", web_path, "#{schema.singular}_reset_password_view.ex"])},
      {:eex, "session_view.ex", Path.join([web_prefix, "views", web_path, "#{schema.singular}_session_view.ex"])},
      {:eex, "settings_view.ex", Path.join([web_prefix, "views", web_path, "#{schema.singular}_settings_view.ex"])}
    ]
  end

  defp copy_new_files(%Context{} = context, binding, paths) do
    files = files_to_be_generated(context)
    Mix.Phoenix.copy_from(paths, "priv/templates/phx.gen.auth", binding, files)

    context
  end

  defp inject_conn_case_helpers(%Context{} = context, paths, binding) do
    # TODO: This needs to work with umbrella apps
    # TODO: Figure out what happens if this file isn't here
    test_file = "test/support/conn_case.ex"

    paths
    |> Mix.Phoenix.eval_from("priv/templates/phx.gen.auth/conn_case.exs", binding)
    |> inject_eex_before_final_end(test_file, binding)

    context
  end

  defp print_shell_instructions(%Context{} = context) do
    context
  end

  # The paths to look for template files for generators.
  #
  # Defaults to checking the current app's `priv` directory,
  # and falls back to phx_gen_auth's `priv` directory.
  defp generator_paths do
    [".", :phx_gen_auth]
  end

  defp inject_eex_before_final_end(content_to_inject, file_path, binding) do
    file = File.read!(file_path)

    if String.contains?(file, content_to_inject) do
      :ok
    else
      Mix.shell().info([:green, "* injecting ", :reset, Path.relative_to_cwd(file_path)])

      file
      |> String.trim_trailing()
      |> String.trim_trailing("end")
      |> EEx.eval_string(binding)
      |> Kernel.<>(content_to_inject)
      |> Kernel.<>("end\n")
      |> write_file(file_path)
    end
  end

  defp write_file(content, file) do
    File.write!(file, content)
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)
end
