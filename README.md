# Sapi-NT client for Ruby

This is a simple client library for interacting with Sapi-NT APIs in a Ruby or
Rails project. The client is initialised with a reference to the Sapi-NT
modelspec for the API, which is used to generate a custom API class using Ruby
metaprogramming

_N.B. This respository's primary branch name has been updated, please see the
[Main branch](#main-branch) section below for more information._

## Usage

See [below](#developer-notes) for notes on developing and updating this gem.

### Installation in a project

To add this library to your Ruby or Rails project, addd this line to your
application's `Gemfile`:

```ruby
source "https://rubygems.pkg.github.com/epimorphics" do
  gem "sapi-client-ruby", "~> 1.3"
end
```

You may need to authenticate with Github to allow Bundler to access the GitHub
Package Registry. To authenticate manually, configure Bundler to use your
personal access token, replacing USERNAME with your GitHub username, TOKEN with
your personal access token:

```sh
bundle config https://rubygems.pkg.github.com/epimorphics USERNAME:TOKEN
```

**Note** that in Epimorphics' projects, our standard pattern is to include a
`Makefile` in each project, which typically will include an `auth` target for
authenticating with the GitHub package registry. Thus an equivalent, but
simpler, command to use instead of the line above is:

```sh
make auth
```

This will prompt you to provide a Github personal access tokenn (PAT). See notes
on the [Epimorphics
Wiki](https://github.com/epimorphics/internal/wiki/Ansible-CICD#creating-a-pat-for-gpr-access)
about creating a PAT.

### Command line usage

To aid debugging and exploring a Sapi-NT endpoint, this library has a
command-line tool `sapi`.  As required inputs, the tool needs both the base URL
for the Sapi-NT API instance (e.g. `http://localhost:8080`), and the location of
the Sapi-NT modelspec files (see [Modelspec files](#modelspec-files) below).
These can either be passed as command-line arguments, or as environment variables:

```sh
sapi -b http://localhost:8080 -s test/fixtures/unified-view/application.yaml inspect
```
or
```sh
export SAPI_BASE_URL=http://localhost:8080
export SAPI_SPEC_FILE=test/fixtures/unified-view/application.yaml
sapi inspect
```
or, using the endpoint specs directory
```sh
sapi -b http://localhost:8080 -s test/fixtures/unified-view/endpointSpecs inspect
```

See `sapi --help` for more details.

Within a project that depends on `sapi-client-ruby` in the Gemfile, the `sapi`
command should just work. However, it may be helpful to install it outside of a
specific project, so that the `sapi` command may also be used from anywhere.
Normally, `gem install` will normally only install a Rubygem from the
`rubygems.org` directory. You can install this gem from the Github package
registry. Please note: You have to add your credentials in line and you cannot
use the `~/.gem/credentials` with gem install

```sh
gem install sapi-client-ruby --version "1.0.0" --source "https://{username}:{token}@rubygems.pkg.github.com/epimorphics"
```

Then `sapi` should be on your `$PATH`:

```sh
ian@ian-desktop-2 $ cd $HOME
ian@ian-desktop-2 $ sapi -h
Usage:
  sapi [-b SAPI_BASE_URL] [-s SAPI_SPEC_FILE] inspect
....
```

#### Command: inspect

Inspect is used to list the available endpoints for a SAPI instance, together
with the Ruby-ified name that can be used to refer to them. E.g:

```sh
$ export SAPI_BASE_URL=http://localhost:8080
$ export SAPI_SPEC_FILE=./test/fixtures/unified-view/application.yaml
$ sapi inspect
authority_list
  /food-businesses/authority
  'List of authorities'
  Views: default
  Resource class: Authority

establishment_list
  /food-businesses/establishment
  'List of establishments'
  Views: default, compact
  Resource class: Establishment

  ....
```

#### Commands to invoke an API endpoint

The keys for each of the sections of the `inspect` command, e.g.
`authority_list` are the names of the Ruby methods that can be invoked on the
service object to call that API method. We can also use that method name as a
command action in the CLI:

```sh
  $ export SAPI_BASE_URL=http://localhost:8080
  $ export SAPI_SPEC_FILE=./test/fixtures/unified-view/application.yaml
  $ sapi inspection_list
  [{"@id"=>
      "http://data.food.gov.uk/food-businesses/establishment/NL7L5Y-547WTK-2N8P8W/inspection/2009-04-22",
    "confidenceScore"=>0,
    "establishment"=>
      {"@id"=>
        "http://data.food.gov.uk/food-businesses/establishment/NL7L5Y-547WTK-2N8P8W",
      "authorityEstablishmentID"=>"S10JWMWEST/1",
      "establishmentType"=>
        {"@id"=>"http://data.food.gov.uk/codes/business/establishment/RC-CE"},
      "registrationAuthority"=>
        {"@id"=>"http://data.food.gov.uk/codes/reference-number/authority/4308",
        "prefLabel"=>"North Somerset Council"},
      "tradingName"=>"The Willows"},
    "hygieneScore"=>5,
    "inspectionDateTime"=>"2009-04-22T00:00:00",
    "overallAnnex5Score"=>40,
    "publicationDateTime"=>"2014-06-03T11:13:00",
    "rating"=>
      {"@id"=>
        "http://data.food.gov.uk/vocabularies/def/core/rating-schemes/fhrs-5",
      "label"=>["fhrs-5"],
      "numericValue"=>5,
      "prefLabel"=>["fhrs-5"],
      "ratingScheme"=>
        {"@id"=>
          "http://data.food.gov.uk/vocabularies/def/core/rating-schemes/fhrs"},
      "ratingValue"=>"5"},
    "ratingValue"=>"5",
    "structuralScore"=>5},
  ....
```

By default, the output will be the list of items in Ruby hash format. To view
the raw JSON output, use the `-j` option:

```sh
$ sapi inspection_list -j
{
  "meta": {
    "@id": "http://data.food.gov.uk/food-businesses/inspection",
    "comment": "FSA Unified View API",
    "hasFormat": [
      "http://data.food.gov.uk/food-businesses/inspection.html",
      "http://data.food.gov.uk/food-businesses/inspection.rdf",
      "http://data.food.gov.uk/food-businesses/inspection.csv",
      "http://data.food.gov.uk/food-businesses/inspection.ttl",
      "http://data.food.gov.uk/food-businesses/inspection.geojson"
    ],
    "license": "",
    "licenseName": "",
    "limit": 1000,
    "publisher": "",
    "version": "0.1"
  },
  "items": [
    {
      "@id": "http://data.food.gov.uk/food-businesses/establishment/NL7L5Y-547WTK-2N8P8W/inspection/2009-04-22",
      "confidenceScore": 0,
      "establishment": {
        "@id": "http://data.food.gov.uk/food-businesses/establishment/NL7L5Y-547WTK-2N8P8W",
        "authorityEstablishmentID": "S10JWMWEST/1",
        "establishmentType": {
          "@id": "http://data.food.gov.uk/codes/business/establishment/RC-CE"
        },
        "registrationAuthority": {
          "@id": "http://data.food.gov.uk/codes/reference-number/authority/4308",
          "prefLabel": "North Somerset Council"
        },
        "tradingName": "The Willows"
      },
      "hygieneScore": 5,
      "inspectionDateTime": "2009-04-22T00:00:00",
      "overallAnnex5Score": 40,
      "publicationDateTime": "2014-06-03T11:13:00",
      "rating": {
```

To limit the number of returned results, set the query limit with the `-l`
parameter:

```sh
$ sapi establishment_list -l 1
[{"@id"=>
    "http://data.food.gov.uk/food-businesses/establishment/MBTM1R-A8K4VZ-2FJCYJ",
  "authorityEstablishmentID"=>"S10JWMPARK/1",
  "establishmentRegistration"=>
    [{"@id"=>
      "http://data.food.gov.uk/food-businesses/establishmentRegistration/MBTM1R-A8K4VZ-2FJCYJ"}],
  "establishmentStatus"=>
    {"@id"=>
      "http://data.food.gov.uk/vocabularies/def/establishment-status/fhrs-included"},
  "establishmentType"=>
...
```

Where a URL path expects one or more variables, these can be passed by adding
more parameters:

```sh
$ sapi establishment_item MBTM1R-A8K4VZ-2FJCYJ -j
{
  "meta": {
    "@id": "http://data.food.gov.uk/food-businesses/establishment/MBTM1R-A8K4VZ-2FJCYJ",
    "comment": "FSA Unified View API",
    "hasFormat": [...],
    "license": "",
    "licenseName": "",
    "publisher": "",
    "version": "0.1"
  },
  "items": [
    {
      "@id": "http://data.food.gov.uk/food-businesses/establishment/MBTM1R-A8K4VZ-2FJCYJ",
      "authorityEstablishmentID": "S10JWMPARK/1",
      "authorityID": "327",
```

### Using Sapi-client from code

Create a new instance of the `SapiClient::Application`, initialised with the
base URL and either the location of the root YAML file for the application, or 
the directory containing the endpoint specification YAML files (see [Modelspec 
files](#modelspec-files) below).

```ruby
irb(main):001:0> app = SapiClient::Application.new('http://localhost:8080', 'test/fixtures/unified-view/application.yaml')
=> #<SapiClient::Application:0x000055c6ef963500 @base_url="http://localhost:8080",
```

Create an `Instance` of the API, which will be decorated with methods
corresponding to the API endpoints:

```ruby
irb(main):002:0> inst = app.instance
=> #<SapiClient::Instance:0x000055c6ef900180>
irb(main):003:0> inst.public_methods
=> [:inspection_list, :inspection_list_json, :inspection_list_spec,
    :establishment_list, :establishment_list_json, ...
```

The `*_json` variant of the method will return the raw JSON output. The `*_spec`
variant will return the specification of the API endpoint (including the name,
description, etc), while the unadorned version will return the item as a Ruby
object.

#### Wrapper classes

When calling the `*_json` methods, the return value is just JSON, expressed as a
Ruby `Hash`. Hash presents a fairly low-level API to interact with the data, so
when calling the main item-getting API methods, the return value will be wrapped
via some facade class. The base facade is `SapiClient::SapiResource`.
SapiResource has methods to:

- traverse paths through the structure (e.g. `establishment.authority.name`)
- provide convenience access to common fields, e.g. `uri`
- map Ruby method calls to fields in the underlying JSON (e.g. a resource with a
  `name` property in JSON will respond to a `.name()` method call)
- pick the best option from a list of language-tagged literals, given a
  preferred language.

SapiResource is designed to function well as a base class for more
domain-specific facade classes, such as `Establishment` for establishment
resources.

To associate the values of an endpoint with a facade class, there are a number
of options:

- a class may be passed via the `wrapper` option when invoking an API
  endpoint method. E.g: `myEndpoint.establishment_list(_limit: 1, wrapper:
  MyClass)`
- if no explicit `wrapper option is available`, the endpoint will look for a
  class that has the same name as the resource-type for the endpoint (e.g. an
  establishments endpoint will have a resource type of `:Establishment`, which
  will then look for an `Establishment` class in Ruby's root namespace)
- if no matching resource-type class can be found, `SapiClient::SapiResource`
  will be used as a default.

#### Options

The endpoint methods that actually call the endpoint (i.e. not `_spec`) take a
hash of options, e.g. the query limit:

```ruby
inst.inspection_list(_limit: 10)
```

Where an API URL takes a path parameter, also pass this using the options:

```ruby
inst.establishment_item(id: 'MBTM1R-A8K4VZ-2FJCYJ')
```

#### Pagination

It is convenient to have a proxy-pattern object that denotes a collection of
value from the endpoint. This proxy can change its parameters, such as the limit
or offset into the list of values, sort parameter, etc, before being manifested
as an actual set of endpoint items by invoking the API. This pattern has been
designed to work comfortably with pagination gems such as
[Pagy](https://github.com/ddnexus/pagy)

Example:

```ruby
instance = ....
endpoint_values =
  SapiClient::EndpointValues.new(instance, :establishment_list)
  .limit(25)
  .offset(400)
  .sort('tradingName')
collection = endpoint_values.to_a
```

#### Instrumentation through `ActiveSupport::Notification`

To assist with adding Prometheus monitoring of an application's interaction with
a remote SapiNT endpoint, this client library will emit `ActiveSupport`
`Notification` events, assuming it's being run in a Rails environment. These
events can be subscribed to, and used to add data to Prometheus client gauges.

The events emitted are:

- `response.sapi_nt` which will record normal responses, including response code
- `connection_failure.sapi_nt` which will record events where Faraday was unable
  to connect to the remote endpoint
- `service_exception.sapi_nt` which records other errors states, not including
  connection failure

## Developer notes

### Modelspec files

Both `sapi-nt` and `sapi-client-ruby` are configured using a set of "modelspec"
files that detail the endpoint URL templates, arguments and responses of a given 
API.

`sapi-nt` uses an `application.yaml` configuration file that, amongst other things, 
points to the location of the directory of these modelspec (YAML) files, although 
often these are resources in a JAR file, so use Java's classpath machinery.

As a step away from too closely coupling `sapi-nt` and `sapi-client-ruby`, we now 
additionally allow initialization of the `SapiClient::Application` using the 
location of the directory containing the modelspec files, usually called 
`endpointSpecs`.

### Main branch

If you have already cloned the repository to your local instance, you will need
to run the following commands to update the primary branch name:

```sh
git branch -m master main
git fetch origin
git branch -u origin/main main
git remote set-head origin -a
```

Otherwise , after checking out the repo, run `make setup` to install
dependencies. Then, run `make test` to run the tests. You can also run `make
console` for an interactive prompt that will allow you to experiment.

### Code standards

Rubocop should always return zero warnings. Run `make lint` to run RuboCop.

### Tests

Run the test suite with `make test`. Ideally, the test coverage reported by
Minitest should not go down as new code is added.

### Publishing

This gem is published to the [GitHub Package
Registry](https://github.com/epimorphics/sapi-client-ruby/packages/)

To publish a new version of this gem:

- make the required changes, and have the PR peer-reviewed by at least one other
  person
- increment the version number `lib/sapi_client/version.rb` according to whether
  this is a major, minor or fix change
- update the `CHANGELOG.md`
- ensure that `make test` and `make lint` are both free of errors
- build the gem and push it to the registry with `make publish`

### Contributing

Bug reports and pull requests are welcome on GitHub at
<https://github.com/epimorphics/sapi-client-ruby>. This project is intended to
be a safe, welcoming space for collaboration, and contributors are expected to
adhere to the [Contributor Covenant](http://contributor-covenant.org) code of
conduct.

### License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

### Code of Conduct

Everyone interacting in the Sapi::Client::Ruby project’s codebases, issue
trackers, chat rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/epimorphics/sapi-client-ruby/blob/master/CODE_OF_CONDUCT.md).
