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

See `bin/sapi -h` for more details.

### Commands: inspect

Inspect is used to list the available endpoints for a SAPI instance, together with the
Ruby-ified name that can be used to refer to them. E.g:

    $ export SAPI_BASE_URL=http://localhost:8080
    $ export SAPI_SPEC_FILE=./test/fixtures/application.yaml
    $ bin/sapi inspect
    authority_list
     /food-businesses/authority
     'List of authorities'

    establishment_list
     /food-businesses/establishment
     'List of establishments'

    establishment_type
     /food-businesses/establishment-types
     'List of establishment types'

    establishment_item
     /food-businesses/establishment/{__id}
     'A single establishment'
     vars: id


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ijdickinson/sapi-nt-client-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Sapi::Nt::Client::Ruby project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ijdickinson/sapi-nt-client-ruby/blob/master/CODE_OF_CONDUCT.md).
