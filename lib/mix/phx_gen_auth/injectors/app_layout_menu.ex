defmodule Mix.Phx.Gen.Auth.Injectors.AppLayoutMenu do
  @moduledoc false

  alias Mix.Phoenix.Schema
  alias Mix.Phx.Gen.Auth.Injector

  def inject(file, %Schema{} = schema) when is_binary(file) do
    with {:error, :unable_to_inject} <- inject_at_end_of_nav_tag(file, schema),
         {:error, :unable_to_inject} <- inject_after_opening_body_tag(file, schema) do
      {:error, :unable_to_inject}
    end
  end

  def help_text(file_path, %Schema{} = schema) do
    """
    Add a render call for #{inspect(menu_name(schema))} to #{Path.relative_to_cwd(file_path)}:

      <nav role="navigation">
        #{code_to_inject(schema)}
      </nav>
    """
  end

  def code_to_inject(%Schema{} = schema) do
    "<%= render \"#{menu_name(schema)}\", assigns %>"
  end

  def menu_name(%Schema{} = schema) do
    "_#{schema.singular}_menu.html"
  end

  defp inject_at_end_of_nav_tag(file, schema) do
    Injector.inject_unless_contains(
      file,
      code_to_inject(schema),
      &Regex.replace(~r/(\s*)<\/nav>/m, &1, "\\1  #{&2}\\0", global: false)
    )
  end

  defp inject_after_opening_body_tag(file, schema) do
    anchor_line = "<body>"

    Injector.inject_unless_contains(
      file,
      code_to_inject(schema),
      # Matches the entire line containing `anchor_line` and captures
      # the whitespace before the anchor. In the replace string, the
      # entire matching line is inserted with \\0, then a newline then
      # the indent that was captured using \\1. &2 is the code to
      # inject.
      &Regex.replace(~r/^(\s*)#{anchor_line}.*(\r\n|\n|$)/Um, &1, "\\0\\1  #{&2}\\2", global: false)
    )
  end
end
