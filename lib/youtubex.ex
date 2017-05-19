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

  def search(term, max_results \\ 10) do
    GenServer.call(__MODULE__, {:search, term, max_results})
  end

  def search_channel(display_name, max_results \\ 10) do
    GenServer.call(__MODULE__, {:search_channel, display_name, max_results})
  end

  def my_videos() do
    GenServer.call(__MODULE__, :my_videos)
  end

  def test() do
    GenServer.call(__MODULE__, :test)
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

  def handle_call({:search, term, max_results}, _from, state) do
    api_key = state[:api_key]
    url = gen_request_url(api_key, :search, %{max_results: max_results , query: term})
    IO.puts "Checking this: \n #{url}"
    result = HTTPoison.get(url) |> response_parser
    {:reply, result, state}
  end

  def handle_call({:search_channel, term, max_results}, _from, state) do
    api_key = state[:api_key]
    url = gen_request_url(api_key, :search, %{max_results: max_results , type: :channel, query: term})

    IO.puts "Checking this: \n #{url}"
    result = HTTPoison.get(url) |> response_parser
    {:reply, result, state}
  end

  def handle_call(:my_videos, _from, state) do
    api_key = state[:api_key]
    url = gen_request_url(api_key, :channel, %{action: :mine})
    IO.puts "Checking this: \n #{url}"
    result = HTTPoison.get(url) |> response_parser
    {:reply, result, state}
  end

  def handle_call(:test, _from, state) do
    api_key = state[:api_key]
    url = "https://www.googleapis.com/youtube/v3/channels?key=#{api_key}&part=id&forUsername=eveevans"
    result = HTTPoison.get(url) |> response_parser
    {:reply, result, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  ############################################
  ############ Helper Functions###############
  ############################################

  defp gen_request_url(api_key, resource, params = %{}) do
    resource_param = parse_resource(resource)
    api_key_param = parse_api_key(api_key)
    base_url = "https://www.googleapis.com/youtube/v3/" <> resource_param <> api_key_param
    complete_request(base_url, resource, params)
  end

  defp parse_resource(resource) do
    case resource do
      :search -> "search?"
      :channel -> "channels?"
    end
  end

  defp parse_api_key(api_key) do
    case api_key do
      :none -> ""
      key -> "key=#{key}"
    end
  end

  defp complete_request(base_url, :search, %{max_results: max_results, query: term}) do
    request_url = base_url
    <> "&part=snippet"
    <> "&maxResults=#{max_results}"
    <> "&query=#{term}"
    request_url
  end

  defp complete_request(base_url, :search, %{max_results: max_results, type: :channel ,query: term}) do
    request_url = base_url
    <> "&part=snippet"
    <> "&maxResults=#{max_results}"
    <> "&type=channel"
    <> "&query=#{term}"
    request_url
  end

  defp complete_request(base_url, :channel, %{action: :mine}) do
    request_url = base_url
    <> "&part=contentDetails"
    <> "&mine=true"
    request_url
  end

  defp complete_request(base_url, :channel, %{action: _action}) do
    request_url = base_url
    request_url
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
