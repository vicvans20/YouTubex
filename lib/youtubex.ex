defmodule Youtubex do

  @base_url "https://www.googleapis.com/youtube/v3/"

  @initial_state %{
    api_key: nil,
    access_token: nil,
  }
  @moduledoc """
  Documentation for Youtubex.
  """
  use GenServer
  
  ############################
  ############ API ###########
  ############################

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def search(term) do
    GenServer.call(__MODULE__, {:search, term})
  end

  def search_channel(display_name) do
    GenServer.call(__MODULE__, {:search_channel, display_name})
  end

  def my_channel() do
    GenServer.call(__MODULE__, :my_channel)
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
  def init(opts) do
    state = @initial_state
      |> Map.put(:api_key, opts[:api_key] || :none)
      |> Map.put(:access_token, opts[:access_token] || :none)
    {:ok, state}
  end

  def handle_call({:search, term}, _from, state) do
    api_key = state[:api_key]
    url = gen_request_url(api_key, :search, %{query: term})

    IO.puts "Checking this: \n #{url}"
    result = HTTPoison.get(url) |> response_parser
    {:reply, result, state}
  end

  def handle_call({:search_channel, term}, _from, state) do
    api_key = state[:api_key]
    url = gen_request_url(api_key, :search, %{type: :channel, query: term})

    IO.puts "Checking this: \n #{url}"
    result = HTTPoison.get(url) |> response_parser
    {:reply, result, state}
  end

  def handle_call(:my_channel, _from, state) do
    token = state[:access_token]
    url = gen_request_url(:oauth2, token, :channels, %{action: :mine})
    IO.puts "Checking this: \n #{url}"
    result = HTTPoison.get(url) |> response_parser
    {:reply, result, state}
  end

  def handle_call(:test, _from, state) do
    api_key = state[:api_key]
    # url = "https://www.googleapis.com/youtube/v3/channels?key=#{api_key}&part=id&forUsername=eveevans"
    url = "https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&playlistId=WL&access_token=ya29.GlxPBPvdat29lSZ5YgxDm7tgF-cCylRViAuEq-DHQE0wG0DWQ9fGOvVzvB2IU9kDEYBwkq9A7oqdP-G9hq76KzhHFsBsWAT9akvJbUTWGwN8VFWZbVas_U5Ci1FBwQ"
    result = HTTPoison.get(url) |> response_parser
    {:reply, result, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  ############################################
  ############ Helper Functions###############
  ############################################

  # For oauth2 required resources
  defp gen_request_url(:oauth2, token, resource, params = %{}) do
    request_params = parse_params(params)
    request_url = build_resource_request(resource, request_params)
    <> "&access_token=#{token}"
    request_url
  end

  # With api key
  defp gen_request_url(api_key, resource, params = %{}) do
    request_params = parse_params(params)
    request_url = build_resource_request(resource, request_params)
    <> "&key=#{api_key}"
    request_url
  end
  
  # Without api key
  defp gen_request_url(:none, resource, params = %{}) do
    request_params = parse_params(params)
    build_resource_request(resource, request_params)
  end


  # Build base resource url request according to the endpoint
  defp build_resource_request(:search, %{max_results: max_results, part: part ,query: term}) do
    request_url = @base_url
    <> "search?"
    <> "part=#{part}"
    <> "&maxResults=#{max_results}"
    <> "&query=#{term}"
    request_url
  end

  defp build_resource_request(:search, %{max_results: max_results, part: part ,type: :channel ,query: term}) do
    request_url = @base_url
    <> "search?"
    <> "part=#{part}"
    <> "&maxResults=#{max_results}"
    <> "&type=channel"
    <> "&query=#{term}"
    request_url
  end

  defp build_resource_request(:channels, %{action: :mine}) do
    request_url = @base_url
    <> "channels?"
    <> "part=contentDetails"
    <> "&mine=true"
    request_url
  end

  defp build_resource_request(:channel, _any) do
    request_url = @base_url
    request_url
  end

  defp parse_params(params) do
    parsed_params = params # Get extra non-default params like term
    parsed_params = parsed_params 
      |> Map.put(:max_results, params[:max_results] || 10)
      |> Map.put(:part, params[:part] || "snippet")
    parsed_params
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
