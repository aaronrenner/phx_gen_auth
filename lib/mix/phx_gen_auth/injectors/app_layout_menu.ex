defmodule Mix.Phx.Gen.Auth.Injectors.AppLayoutMenu do
  @moduledoc false

  alias Mix.Phoenix.Schema
  alias Mix.Phx.Gen.Auth.Injector

  @anchor_line "<body>"

  def inject(file, %Schema{} = schema) when is_binary(file) do
    Injector.inject_unless_contains(
      file,
      code_to_inject(schema),
      # Matches the entire line containing `anchor_line` and captures
      # the whitespace before the anchor. In the replace string, the
      # entire matching line is inserted with \\0, then a newline then
      # the indent that was captured using \\1. &2 is the code to
      # inject.
      &Regex.replace(~r/^(\s*)#{@anchor_line}.*$/m, &1, "\\0\n\\1  #{&2}", global: false)
    )
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
end
