defmodule Phx.Gen.Auth.TestSupport.IntegrationTestHelpers.MixTaskServer do
  use GenServer

  @type prompt_response :: :no_to_all | :yes_to_all | String.t()
  @type opt :: {:prompt_responses, [prompt_response]}

  @type args :: [String.t()]

  @spec start_link(args, [opt]) :: GenServer.on_start()
  def start_link(args, opts) when is_list(args) and is_list(opts) do
    parent_pid = self()
    GenServer.start_link(__MODULE__, {parent_pid, args, opts})
  end

  @spec run(args, [opt]) :: {String.t(), exit_status :: non_neg_integer()}
  def run(args, opts) do
    {:ok, pid} = start_link(args, opts)

    receive do
      {:command_exited, ^pid, {output, exit_code}} ->
        {output, exit_code}
    end
  end

  @impl true
  def init({parent_pid, args, opts}) do
    mix_path = System.find_executable("mix")

    prompt_responses =
      opts
      |> Keyword.get(:prompt_responses, [])
      |> List.wrap()

    port =
      Port.open(
        {:spawn_executable, mix_path},
        [:exit_status, :stderr_to_stdout, args: args, env: [{'MIX_ENV', 'test'}]]
      )

    state = %{
      port: port,
      parent_pid: parent_pid,
      output_iodata: [],
      prompt_responses: prompt_responses
    }

    {:ok, state}
  end

  @impl true
  def handle_info({port, {:data, data}}, %{port: port, output_iodata: output_iodata} = state) do
    data = List.to_string(data)
    state = %{state | output_iodata: [output_iodata | data]}

    state =
      case analyze_output(data) do
        {:prompt, prompt} -> handle_prompt!(prompt, state)
        _ -> state
      end

    {:noreply, state}
  end

  def handle_info({port, {:exit_status, exit_status}}, %{port: port, parent_pid: parent_pid} = state) do
    send(parent_pid, {:command_exited, self(), {get_output(state), exit_status}})
    {:stop, :normal, state}
  end

  defp analyze_output(output) do
    if Regex.match?(~r/\? \[yn\]/i, output) do
      {:prompt, output}
    else
      {:output, output}
    end
  end

  defp handle_prompt!(_prompt, %{prompt_responses: [:no_to_all | _], port: port} = state) do
    Port.command(port, "n\n")
    state
  end

  defp handle_prompt!(prompt, %{prompt_responses: []} = state) do
    raise """
    unexpected prompt

      #{prompt}

    All output:

    #{get_output(state)}
    """
  end

  defp get_output(%{output_iodata: output_iodata}) do
    IO.iodata_to_binary(output_iodata)
  end
end
