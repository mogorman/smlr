<p align="center">
<a href="https://hexdocs.pm/smlr/"><img src="https://img.shields.io/badge/api-docs-green" alt="Docs"/></a>
<a href="https://travis-ci.com/mogorman/smlr"><img src="https://travis-ci.com/mogorman/smlr.svg?branch=master" alt="Build"/></a>
<a href="https://coveralls.io/github/mogorman/smlr?branch=master"><img src="https://coveralls.io/repos/github/mogorman/smlr/badge.svg" alt="Code Coverage"/></a>
<a href="https://hex.pm/packages/smlr"><img src="http://img.shields.io/hexpm/v/smlr.svg" alt="Package"/></a>
<a href="COPYING.txt"><img src="http://img.shields.io/hexpm/l/smlr.svg" alt="License"/></a>
<img src="https://img.shields.io/hexpm/dt/smlr" alt="Downloads"/>
</p>

# Smlr: (gzip, deflate, br, zstd) compressor plug
<!-- end_header -->
Supports gzip, deflate, br, and zstd

Smlr is a plug for phoenix to compress output to the client, and optionally cache it.

It currently supports Gzip, deflate, br, and Zstd algorithms. The backend is pluggable
making it easy for you to add your own compressors.

Local caching of the compressed output is available via cachex, you are able to limit
the number of cached items, and or have a ttl for them.

Metrics are implemented via telemetry.

## Example

```elixir
## in your router simply add
plug(Smlr)
## At the end of your plug chain.

## To compress your websocket traffic add
compress: true
## to your endpoint as described here https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#socket/3-examples
```

## Installation

Add the following to the `deps` block in `mix.exs`:

    {:smlr, "~>1.0.0"}

## Configuration

Configuration can be specified in the `opts` argument to all Smlr
functions, by setting config values with e.g., `Application.put_env`,
or by a combination of the two.

The following configuration options are supported:

* `:enable` enable or disable the plug entirely. Default `true`.
* `:compressors` A list of Modules that follow the Smlr.Compressor behavior. Default ```elixir
    [
      Smlr.Compressor.Gzip,
      Smlr.Compressor.Deflate,
      Smlr.Compressor.Brotli,
      Smlr.Compressor.Zstd
    ]```
* `:compressor_opts` A list of tuples, `{Module, level}` where level is the compression number to set. Default `[]`
* `:cache_opts` A map of options to be set for cachex. Default ```elixir
 cache_opts: %{
      enable: false,
      timeout: :infinity,
      limit: nil
    }```
* `:ignore_client_weight` Compress via the order of the `compressors` list rather than what the client indicated their preference is. Default `false`

## Metrics

Metrics are offered via the [Telemetry
library](https://github.com/beam-telemetry/telemetry). The following
metrics are emitted:
* `[:smlr, :request, :pass]` Client and Server had no compatible compressors, or client did not request compression
* `[:smlr, :request, :compress]` Compressed response
* `[:smlr, :request, :cache]` Served compress content from cache
* `[:smlr, :request, :cache, :not_started]` Cachex was called but had not been started yet.
* `[:smlr, :request, :cache, :miss]`
* `[:smlr, :request, :cache, :hit]`
* `[:smlr, :request, :cache, :set]`

## Contributing

Thanks for considering contributing to this project, and to the free
software ecosystem at large!

Interested in contributing a bug report?  Terrific!  Please open a [GitHub
issue](https://github.com/mogorman/smlr/issues) and include as much detail
as you can.  If you have a solution, even better -- please open a pull
request with a clear description and tests.

Have a feature idea?  Excellent!  Please open a [GitHub
issue](https://github.com/mogorman/smlr/issues) for discussion.

Want to implement an issue that's been discussed?  Fantastic!  Please
open a [GitHub pull request](https://github.com/mogorman/smlr/pulls)
and write a clear description of the patch.
We'll merge your PR a lot sooner if it is well-documented and fully
tested.

## Authorship and License

Copyright 2020, Matthew O'Gorman.

This software is released under the MIT License.
