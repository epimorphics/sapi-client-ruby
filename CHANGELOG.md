# Changelog: Sapi Client for Ruby

All notable changes will be documented in this file.

## [Unreleased]
### Changed
- Renamed EndpointSpec to EndpointGroup to reduce confusion. Even though the
  containing directory is `endpointSpecs`, a `*.yaml` file in that directory
  typically contains multiple endpoints. Each document in the YAML stream is
  a spec of an endpoint, so it was ambiguous whether an EndpointSpec was the
  container for a set of endpoints, or a single endpoint. Hence the change of
  name.
