defmodule Smlr do
  ## (I stole this trick from Jose --pete) --mog
  @moduledoc File.read!("README.md") |> String.split("<!-- end_header -->") |> Enum.at(1)

  @behaviour Plug
  require Logger

  alias Plug.Conn
  alias Smlr.{Cache, Config}

  @impl Plug
  @doc ~S"""
  Init function sets all default variables and .
  """
  @spec init(Keyword.t()) :: Keyword.t()
  def init(opts) do
    opts
  end

  defp parse_request_header([], _compressors, _ignore_client_weight) do
    nil
  end

  defp parse_request_header([header], compressors, true) do
    schemes =
      String.downcase(header)
      |> String.split(",")
      |> Enum.map(fn scheme ->
        scheme
        |> String.split(";")
        |> Enum.at(0)
        |> String.trim()
      end)

    Enum.find(compressors, nil, fn compressor ->
      compressor.name() in schemes
    end)
  end

  defp parse_request_header([header], compressors, false) do
    schemes = String.split(header, ",")

    {choice, _weight} =
      Enum.reduce(schemes, {nil, -1}, fn scheme, acc ->
        split_scheme = String.split(scheme, ";")

        case Enum.count(split_scheme) do
          1 ->
            Enum.at(split_scheme, 0)
            |> String.trim()
            |> String.downcase()
            |> enable_compressor(compressors)
            |> choose_compressor(acc)

          2 ->
            new_weight = get_weight(Enum.at(split_scheme, 1))

            Enum.at(split_scheme, 0)
            |> String.trim()
            |> String.downcase()
            |> enable_compressor(compressors, new_weight)
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

  defp enable_compressor(compression, compressors, weight \\ 0) do
    case Enum.find(compressors, nil, fn compressor ->
           compressor.name() == compression
         end) do
      nil ->
        {nil, -1}

      compressor ->
        {compressor, weight}
    end
  end

  @impl Plug
  @doc ~S"""
  Call function. we check to see if the client has requested compression if it has, we register call back and compress before sending
  """
  @spec call(Conn.t(), Keyword.t()) :: Conn.t()
  def call(conn, opts) do
    case Config.config(:enable, opts) do
      true ->
        conn
        |> Conn.get_req_header("accept-encoding")
        |> parse_request_header(Config.config(:compressors, opts), Config.config(:ignore_client_weight, opts))
        |> pass_or_compress(conn, opts)

      false ->
        conn
    end
  end

  defp pass_or_compress(nil, conn, _opts) do
    :telemetry.execute([:smlr, :request, :pass], %{}, %{path: conn.request_path})
    conn
  end

  defp pass_or_compress(compressor, conn, opts) do
    Conn.register_before_send(conn, fn conn ->
      compress_response(conn, conn.resp_body, opts ++ [compressor: compressor])
    end)
  end

  defp check_content_type?(true, _, _) do
    true
  end

  defp check_content_type?(false, [application_type], opts) do
    Enum.any?(Config.config(:types, opts), fn type ->
      String.contains?(application_type, type) end)
  end

  def compress_response(conn, nil, _opts) do
    conn
  end

  def compress_response(conn, body, opts) do
    with all_types <- Config.config(:all_types, opts),
         true <- check_content_type?(all_types, Conn.get_resp_header(conn, "content-type"), opts) do
      compressor = Keyword.get(opts, :compressor)

      conn
      |> Conn.put_resp_header("content-encoding", compressor.name())
      |> Map.put(:resp_body, compress(body, conn.request_path, compressor, opts))
    else
      _ ->
        conn
    end
  end

  defp compress(body, path, compressor, opts) do
    # We do this because io lists are a pain and strings are easy
    case Cache.get(body, compressor.name(), compressor.level(opts), Config.config(:cache_opts, opts)) do
      nil ->
        :telemetry.execute([:smlr, :request, :compress], %{}, %{
          path: path,
          compressor: compressor.name(),
          level: compressor.level(opts)
        })

        compressor.compress(body, opts)
        |> Cache.set(body, compressor.name(), compressor.level(opts), Config.config(:cache_opts, opts))

      compressed ->
        :telemetry.execute([:smlr, :request, :cache], %{}, %{
          path: path,
          compressor: compressor.name(),
          level: compressor.level(opts)
        })

        compressed
    end
  end
end
