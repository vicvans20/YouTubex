defmodule Youtubex do
  @initial_state %{
    api_key: nil,
  }
  @moduledoc """
  Documentation for Youtubex.
  """
  use GenServer
  
  ############################
  ############ API ###########
  ############################

  def start_link(api_key \\ :none, opts \\ []) do
    GenServer.start_link(__MODULE__, {api_key, opts}, name: __MODULE__)
  end

  def search(term) do
    GenServer.call(__MODULE__, {:search, term})
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  ############################################
  ############# Callback Functions ###########
  ############################################
  def init({api_key, _opts}) do
    state = Map.put(@initial_state, :api_key, api_key)
    {:ok, state}
  end

  def handle_call({:search, term}, _from, state) do
    api_key = state[:api_key]
    url = gen_base_url(api_key) <> "&part=snippet&maxResults=10&query=#{term}"
    IO.puts "Checking this: \n #{url}"
    result = HTTPoison.get(url) |> response_parser
    {:reply, result, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  ############################################
  ############ Helper Functions###############
  ############################################

  defp gen_base_url(:none) do
   "https://www.googleapis.com/youtube/v3/search?"
  end

  defp gen_base_url(api_key) do
   "https://www.googleapis.com/youtube/v3/search?key=#{api_key}"
  end

  defp response_parser({:ok, %HTTPoison.Response{status_code: 200, body: body} }) do
    {:ok, Poison.Parser.parse!(body)}
  end

  defp response_parser( {:ok, %HTTPoison.Response{status_code: 400, body: body}} ) do
    {:bad_request, Poison.Parser.parse!(body)}
  end

   defp response_parser( {:ok, %HTTPoison.Response{status_code: 403, body: body}} ) do
    {:unauthenticate, Poison.Parser.parse!(body)}
  end

  defp response_parser( {:ok, %HTTPoison.Response{status_code: 404, body: _body} }) do
    :not_found
  end

  defp response_parser( {:error, %HTTPoison.Error{reason: reason}} ) do
    {:error, reason}
  end

  defp response_parser(anything) do
    IO.inspect(anything)
    :unknown_error
  end


end
