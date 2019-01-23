# SAPI-NT client ruby

This is a simple client library for interacting with SAPI-NT APIs in a Ruby
or Rails project. The client is initialised with a reference to the SAPI-NT
modelspec for the API, which is used to generate a custom API class using
Ruby metaprogramming

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sapi-client-ruby'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sapi-client-ruby

## Command line usage

To aid debugging and exploring a SAPI endpoint, this library has a command-line
tool `bin/sapi`.  As required inputs, the tool needs both the base URL for the
SAPI API instance (e.g. `http://localhost:8080`), and the location of the SAPI
configuration root file. These can either be passed as command-line arguments, or
as environment variables:

    bin/sapi -b http://localhost:8080 -s test/fixtures/application.yaml inspect

    SAPI_BASE_URL=http://localhost:8080 bin/sapi -s test/fixtures/application.yaml inspect

See `bin/sapi --help` for more details.

### Command: inspect

Inspect is used to list the available endpoints for a SAPI instance, together with the
Ruby-ified name that can be used to refer to them. E.g:

    $ export SAPI_BASE_URL=http://localhost:8080
    $ export SAPI_SPEC_FILE=./test/fixtures/application.yaml
    $ bin/sapi inspect
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

### Commands to invoke an API endpoint

The keys for each of the sections of the `inspect` command, e.g. `authority_list`
are the names of the Ruby methods that can be invoked on the service object to
call that API method. We can also use that method name as a command action in the
CLI:

    $ export SAPI_BASE_URL=http://localhost:8080
    $ export SAPI_SPEC_FILE=./test/fixtures/application.yaml
    $ bin/sapi inspection_list
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

By default, the output will be the list of items in Ruby hash format. To view
the raw JSON output, use the `-j` option:

    $ bin/sapi inspection_list -j
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

To limit the number of returned results, set the query limit with the `-l`
parameter:

    $ bin/sapi establishment_list -l 1
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

Where a URL path expects one or more variables, these can be passed by adding
more parameters:

    $ bin/sapi establishment_item MBTM1R-A8K4VZ-2FJCYJ -j
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

## Using Sapi-client from code

Create a new instance of the `SapiClient::Application`, initialised with the base
URL and the location of the root YAML file for the application:

    irb(main):001:0> app = SapiClient::Application.new('http://localhost:8080', 'test/fixtures/application.yaml')
    => #<SapiClient::Application:0x000055c6ef963500 @base_url="http://localhost:8080",

Create an `Instance` of the API, which will be decorated with methods corresponding
to the API endpoints:

    irb(main):002:0> inst = app.instance
    => #<SapiClient::Instance:0x000055c6ef900180>
    irb(main):003:0> inst.public_methods
    => [:inspection_list, :inspection_list_json, :inspection_list_spec,
        :establishment_list, :establishment_list_json, ...

The `_json` variant of the method will return the raw JSON output. The `_spec`
variant will return the specification of the API endpoint (including the name,
description, etc), while the unadorned version will return the item as a Ruby object.

TODO: wrapping the returned item in a facade-pattern class

The endpoint methods that actually call the endpoint (i.e. not `_spec`) take
a hash of options, e.g. the query limit:

    inst.inspection_list(_limit: 10)

Where an API URL takes a path parameter, also pass this using the options:

    inst.establishment_item(id: 'MBTM1R-A8K4VZ-2FJCYJ')

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/epimorphics/sapi-client-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Sapi::Client::Ruby project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/epimorphics/sapi-client-ruby/blob/master/CODE_OF_CONDUCT.md).
