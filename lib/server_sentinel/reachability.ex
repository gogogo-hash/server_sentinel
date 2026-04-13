
defmodule ServerSentinel.Reachability do
  use GenServer

  @check_interval :timer.minutes(1)

  ## Public API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  ## GenServer callbacks

  @impl true
  def init(_opts) do
    state = %{
      status: :unknown,        # :reachable | :unreachable | :unknown
      last_change: nil
    }

    send(self(), :check)
    {:ok, state}
  end

  @impl true
  def handle_info(:check, state) do
    new_status = check_server()

    state =
      if new_status != state.status do
        handle_state_change(state.status, new_status)
        %{
          status: new_status,
          last_change: DateTime.utc_now()
        }
      else
        state
      end

    Process.send_after(self(), :check, @check_interval)
    {:noreply, state}
  end

  ## Internal logic

  defp check_server do
    # placeholder for now
    # return :reachable or :unreachable
    host = "host.server"
    port = 22

timeout_ms = 5_000

  # gen_tcp prefers charlists for hostnames, so convert explicitly
  host_charlist = String.to_charlist(host)

  opts = [
    :binary,
    active: false
  ]

  try do
    case :gen_tcp.connect(host_charlist, port, opts, timeout_ms) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        :reachable

      {:error, _reason} ->
        :unreachable
    end
  rescue
    ArgumentError ->
      # Bad args (wrong host/port type, etc.) should not crash the GenServer
      :unreachable
  end



  end

  defp handle_state_change(:reachable, :unreachable) do
    notify("server became UNREACHABLE")
  end

  defp handle_state_change(:unreachable, :reachable) do
    notify("server is reachable again")
  end

  defp handle_state_change(:unknown, new_status) do
    notify("Initial server state: #{new_status}")
  end

  defp notify(message) do
    IO.puts("[SERVER SENTINEL] #{message}")
  end
end
