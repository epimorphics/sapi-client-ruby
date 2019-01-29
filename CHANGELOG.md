# Changelog: Sapi Client for Ruby

All notable changes will be documented in this file.

## [Unreleased]

No changes yet

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
