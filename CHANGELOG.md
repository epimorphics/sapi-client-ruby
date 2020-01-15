# Changelog: Sapi Client for Ruby

All notable changes will be documented in this file.

## 0.5.0 - 2020-01-15

- Added a feature to the API of `Instance` to allow a resource with only an
  `@id` property to be resolved by the API. See GH-13.

No changes yet

## [0.4.12]

- Add a feature that allows an API instance to return the base URL for the API.

## [0.4.11]

- Fix GH-11 by supporting multi-valued parameters for filters we pass to Sapi-NT.

## [0.4.10]

- Add a feature to support optional logging of requests and responses.

## [0.4.9]

- Fix GH-10: the lib was using the wrong attribute in JSON-LD for a human language

## [0.4.8]

- Fix regression arising from the use of Faraday instrumentation. This has a
  dependency on `ActiveSupport`, so should only be loaded in a Rails environment

## [0.4.7]

- Add a feature to return the slug from a URI, e.g. `http://wimbledon.org/common`
  has the slug `common`
- Fix API spec parsing to also recognise `forward` endpoint specs

## [0.4.6]

- Generalise the API to instance.get() to allow other content-types to be
  retrieved, not just JSON.

## [0.4.4]

- Fix to allow nested values with non-symbol keys, which was preventing me from
  using path expressions into complex nested values coming from the Sapi API.

## [0.4.3]

### Fixed

- Issue GH-7: allow bindings for path variables to be passed as either string
  keys or symbol keys
- Issue GH-8: don't raise if the API returns HTTP 404. Instead, wrap the JSON
  return value as the item to be returned, which contains various structured
  messages describing the problem.

## [0.4.2]

### Added

- SapiClient::EndpointValues as a proxy for a collection of values that is
  designed to play well with pagination

### Fixed

- Issue GH-6: Sapi-NT endpoint views can be specified inline, as well as
  indirectly by name.

## [0.4.0]

### Changed

- Renamed EndpointSpec to EndpointGroup to reduce confusion. Even though the
  containing directory is `endpointSpecs`, a `*.yaml` file in that directory
  typically contains multiple endpoints. Each document in the YAML stream is
  a spec of an endpoint, so it was ambiguous whether an EndpointSpec was the
  container for a set of endpoints, or a single endpoint. Hence the change of
  name.

### Added

- Added resource wrapper classes, a default wrapper SapiClient::SapiResource
  and strategies for associating wrappers with endpoints. Details in README.
