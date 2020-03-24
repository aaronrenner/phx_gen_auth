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
    |> maybe_inject_helpers()
    |> print_shell_instructions()
  end

  defp prompt_for_conflicts(context) do
    context
    |> files_to_be_generated()
    |> Mix.Phoenix.prompt_for_conflicts()
  end

  defp files_to_be_generated(%Context{schema: schema} = context) do
    [{:eex, "notifier.ex", Path.join([context.dir, "#{schema.singular}_notifier.ex"])}]
  end

  defp copy_new_files(%Context{} = context, binding, paths) do
    files = files_to_be_generated(context)
    Mix.Phoenix.copy_from(paths, "priv/templates/phx.gen.auth", binding, files)

    context
  end

  defp maybe_inject_helpers(%Context{} = context) do
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
end
