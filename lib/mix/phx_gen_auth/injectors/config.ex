defmodule Mix.Phx.Gen.Auth.Injectors.Config do
  @moduledoc false

  alias Mix.Phx.Gen.Auth.{HashingLibrary, Injector}

  def inject(file, %HashingLibrary{} = hashing_library) when is_binary(file) do
    code_to_inject =
      hashing_library
      |> code_to_inject()
      |> String.replace("\n", get_line_ending(file))

    Injector.inject_unless_contains(
      file,
      code_to_inject,
      # Matches the entire line and captures the line ending. In the
      # replace string:
      #
      # * the entire matching line is inserted with \\0,
      # * the actual code is injected with &2,
      # * and the appropriate newlines are injected using \\2.
      &Regex.replace(~r/(use Mix\.Config|import Config)(\r\n|\n|$)/, &1, "\\0\\2#{&2}\\2", global: false)
    )
  end

  def help_text(file_path, %HashingLibrary{} = hashing_library) do
    """
    Add the following to #{Path.relative_to_cwd(file_path)}:

    #{hashing_library |> code_to_inject() |> indent_spaces(4)}
    """
  end

  defp code_to_inject(%HashingLibrary{test_config: test_config}) do
    String.trim("""
    # Only in tests, remove the complexity from the password hashing algorithm
    #{test_config}
    """)
  end

  defp indent_spaces(string, number_of_spaces) when is_binary(string) and is_integer(number_of_spaces) do
    indent = String.duplicate(" ", number_of_spaces)

    string
    |> String.split("\n")
    |> Enum.map(&(indent <> &1))
    |> Enum.join("\n")
  end

  defp get_line_ending(file) do
    case Regex.run(~r/\r\n|\n|$/, file) do
      [line_ending] -> line_ending
      [] -> "\n"
    end
  end
end
