# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sapi_client/version'

Gem::Specification.new do |spec| # rubocop:disable Metrics/BlockLength
  spec.required_ruby_version = '>= 2.5'
  spec.name          = 'sapi-client'
  spec.version       = SapiClient::VERSION
  spec.authors       = ['Ian Dickinson']
  spec.email         = ['i.j.dickinson@gmail.com']

  spec.summary       = 'Adds Ruby support for interacting with a SAPI-NT API'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

    # spec.metadata['homepage_uri'] = 'TODO'
    # spec.metadata['source_code_uri'] = "TODO: Put your gem's public repo URL here."
    # spec.metadata['changelog_uri'] = "TODO: Put your gem's CHANGELOG.md URL here."
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday_middleware', '~> 1.0.0'
  spec.add_dependency 'i18n', '~> 1.5'

  spec.add_development_dependency 'bundler', '~> 2.1.4'
  spec.add_development_dependency 'byebug', '~> 11.1.3'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'minitest-reporters', '~> 1.4.2'
  spec.add_development_dependency 'mocha', '~> 1.12.0'
  spec.add_development_dependency 'rake', '~> 13.0.1'
  spec.add_development_dependency 'rubocop', '~> 1.9.0'
  spec.add_development_dependency 'simplecov', '~> 0.21.1'
  spec.add_development_dependency 'vcr', '~> 6.0.0'
end
