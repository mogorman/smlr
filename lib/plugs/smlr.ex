defmodule Smlr.Plugs.Smlr do
  @behaviour Plug
  @moduledoc ~S"""
  Compresses the output of the plug with the correct compressor,
  if enabled cache the compressed output so that when requested again we can return it instantly
  rather than having to compress it again.

  Add the plug at the bottom of one or more pipelines in `router.ex`:

      pipeline "myapp" do
        # ...
        plug Smlr.Plugs.Smlr, [compressors: ["gzip", "deflate", "br"],
        cache: %{enabled: true, timeout: 3600, max_cache_responses: 10000, name: :smlr}]
      end
  """
  require Logger
  import Plug.Conn

  @impl Plug
  @doc ~S"""
  Init function sets all default variables and .
  """
  def init(opts) when is_list(opts) do
    opts
    |> Enum.chunk_every(2)
    |> Enum.into(%{}, fn [key, val] -> {key, val} end)
    |> init()
  end

  def init(opts) do
    cache =
      case Map.get(opts, :cache) do
        nil ->
          %{enabled: false}

        cache ->
          %{
            enabled: Map.get(cache, :enabled, false),
            timeout: Map.get(cache, :timeout, :infinity),
            max_cache_responses: Map.get(cache, :max_cache_responses, nil),
            name: Map.get(cache, :name, :smlr)
          }
      end

    Smlr.try_start_cache(cache)

    compressors = Smlr.supported_compressors(Map.get(opts, :compressors, ["gzip"]))

    %{
      compressors: compressors,
      cache: cache,
      ignore_client_weight: Map.get(opts, :ignore_client_weight, false)
    }
  end

  defp parse_request_header([], _opts) do
    nil
  end

  defp parse_request_header([header], %{ignore_client_weight: true} = opts) do
    schemes =
      String.downcase(header)
      |> String.split(",")
      |> Enum.map(fn scheme ->
        scheme
        |> String.split(";")
        |> Enum.at(0)
        |> String.trim()
      end)

    Enum.find(opts.compressors, nil, fn compressor ->
      compressor in schemes
    end)
  end

  defp parse_request_header([header], opts) do
    schemes = String.split(header, ",")

    {choice, _weight} =
      Enum.reduce(schemes, {nil, -1}, fn scheme, acc ->
        split_scheme = String.split(scheme, ";")

        case Enum.count(split_scheme) do
          1 ->
            Enum.at(split_scheme, 0)
            |> String.trim()
            |> String.downcase()
            |> enabled_compressor(opts)
            |> choose_compressor(acc)

          2 ->
            new_weight = get_weight(Enum.at(split_scheme, 1))

            Enum.at(split_scheme, 0)
            |> String.trim()
            |> String.downcase()
            |> enabled_compressor(opts, new_weight)
            |> choose_compressor(acc)
        end
      end)

    choice
  end

  defp get_weight(weight) do
    split_string = String.split(weight, "=")

    case Enum.count(split_string) do
      2 ->
        number =
          Enum.at(split_string, 1)
          |> String.trim()

        case String.contains?(number, ".") do
          true ->
            Float.parse(number)

          false ->
            Integer.parse(number)
        end

      _ ->
        -1
    end
  end

  defp choose_compressor({new_choice, new_choice_weight}, {current_choice, current_choice_weight}) do
    case current_choice_weight >= new_choice_weight do
      true ->
        {current_choice, current_choice_weight}

      false ->
        {new_choice, new_choice_weight}
    end
  end

  defp enabled_compressor(compression, %{compressors: schemes}, weight \\ 0) do
    case Enum.any?(schemes, fn scheme -> scheme == compression end) do
      true ->
        {compression, weight}

      false ->
        {nil, -1}
    end
  end

  @impl Plug
  @doc ~S"""
  Call function. we check to see if the client has requested compression if it has, we register call back and compress before sending
  """
  def call(conn, opts) do
    conn
    |> get_req_header("accept-encoding")
    |> parse_request_header(opts)
    |> pass_or_compress(conn, opts)
  end

  defp pass_or_compress(nil, conn, _opts) do
    conn
  end

  defp pass_or_compress(compressor, conn, opts) do
    Plug.Conn.register_before_send(conn, fn conn ->
      compress_response(conn, Map.put(opts, :compressor, compressor))
    end)
  end

  defp compress_response(conn, opts) do
    conn
    |> put_resp_header("content-encoding", opts.compressor)
    |> Map.put(:resp_body, compress(conn.resp_body, opts))
  end

  defp compress(body, opts) do
    # We do this because io lists are a pain and strings are easy
    case Smlr.get_from_cache(body, opts.compressor, opts) do
      nil ->
        Smlr.run_compress(:erlang.iolist_to_binary(body), opts.compressor)
        |> Smlr.set_for_cache(body, opts.compressor, opts)

      compressed ->
        compressed
    end
  end
end
