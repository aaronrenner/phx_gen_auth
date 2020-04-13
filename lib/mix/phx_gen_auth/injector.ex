defmodule Mix.Phx.Gen.Auth.Injector do
  @moduledoc false

  @doc """
  Injects a dependency into the contents of mix.exs
  """
  @spec inject_mix_dependency(String.t(), String.t()) :: {:ok, String.t()} | :already_injected | {:error, :unable_to_inject}
  def inject_mix_dependency(mixfile, dependency) do
    with :ok <- ensure_dependency_not_injected(mixfile, dependency),
         {:ok, new_mixfile} <- do_inject_dependency(mixfile, dependency) do
      {:ok, new_mixfile}
    end
  end

  @doc """
  Injects snippet before the final end in a file
  """
  @spec inject_before_final_end(String.t(), String.t()) :: {:ok, String.t()} | :already_injected
  def inject_before_final_end(code, code_to_inject) when is_binary(code) and is_binary(code_to_inject) do
    if String.contains?(code, code_to_inject) do
      :already_injected
    else
      new_code =
        code
        |> String.trim_trailing()
        |> String.trim_trailing("end")
        |> Kernel.<>(code_to_inject)
        |> Kernel.<>("end\n")

      {:ok, new_code}
    end
  end

  @spec ensure_dependency_not_injected(String.t(), String.t()) :: :ok | :already_injected
  defp ensure_dependency_not_injected(mixfile, dependency) do
    if String.contains?(mixfile, dependency) do
      :already_injected
    else
      :ok
    end
  end

  @spec do_inject_dependency(String.t(), String.t()) :: {:ok, String.t()} | {:error, :unable_to_inject}
  defp do_inject_dependency(mixfile, dependency) do
    string_to_split_on = """
      defp deps do
        [
    """

    case split_with_self(mixfile, string_to_split_on) do
      {beginning, splitter, rest} ->
        new_mixfile = IO.iodata_to_binary([beginning, splitter, "      ", dependency, ?\,, ?\n, rest])
        {:ok, new_mixfile}

      _ ->
        {:error, :unable_to_inject}
    end
  end

  @spec split_with_self(String.t(), String.t()) :: {String.t(), String.t(), String.t()} | :error
  defp split_with_self(contents, text) do
    case :binary.split(contents, text) do
      [left, right] -> {left, text, right}
      [_] -> :error
    end
  end
end
