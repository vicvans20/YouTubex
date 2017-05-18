defmodule Youtubex do
  @initial_state = %{}
  @moduledoc """
  Documentation for Youtubex.
  """
  use GenServer
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
end
