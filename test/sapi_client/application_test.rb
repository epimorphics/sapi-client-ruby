# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class ApplicationTest < Minitest::Test
    describe 'Application' do
      [
        'test/fixtures/unified-view/application.yaml',
        'test/fixtures/unified-view/endpointSpecs'
      ].each do |spec_file_or_dir|
        let(:spec) { spec_file_or_dir }
        let(:base_url) { "http://localhost:#{sapi_api_port}" }

        describe "with #{spec_file_or_dir}" do
          describe '#initialize' do
            it 'should load the application specification given' do
              app = SapiClient::Application.new(base_url, spec)
              _(app.specification).must_be_kind_of Hash
            end

            it 'should raise an error if the spec file does not exist' do
              _(
                -> { SapiClient::Application.new(base_url, 'wimbledon/wombles.yaml') }
              ).must_raise(SapiError)
            end

            it 'should store the base URL' do
              app = SapiClient::Application.new(base_url, spec)
              _(app.base_url).must_equal base_url
            end
          end

          describe '#configuration' do
            it 'should report the application configuration' do
              app = SapiClient::Application.new(base_url, spec)
              _(app.configuration).must_be_kind_of Hash
              assert app.configuration.key?('loadSpecPath')
            end
          end

          describe '#endpoint_group_files' do
            it 'should return the names of all of the endpoint specification files' do
              app = SapiClient::Application.new(base_url, spec)
              file_names = app.endpoint_group_files
              _(file_names.length).must_be :>, 5
              _(file_names).must_include('test/fixtures/unified-view/endpointSpecs/establishment.yaml')
            end
          end

          describe '#endpoints' do
            it 'should return a list of all of the endpoint specification objects' do
              app = SapiClient::Application.new(base_url, spec)
              eps = app.endpoints
              _(eps).must_be_kind_of Array
              _(eps.length).must_be :>, 5

              _(eps.map(&:raw_path)).must_include '/business/id/establishment'
            end
          end

          describe '#instance' do
            it 'should create an instance with methods corresponding to endpoints' do
              app = SapiClient::Application.new(base_url, spec)
              inst = app.instance
              methods = inst.public_methods
              _(methods).must_include(:establishment_list)
              _(methods).must_include(:establishment_list_spec)
            end

            it 'should wrap a list of instances' do
              class ::Establishment # rubocop:disable Lint/ConstantDefinitionInBlock
                def initialize(_json)
                  @invoked = true
                end
                attr_reader :invoked
              end

              app = SapiClient::Application.new(base_url, spec)
              inst = app.instance

              VCR.use_cassette('application.test_instance_wrapping') do
                establishments = inst.establishment_list(_limit: 1)
                _(establishments.first).must_be_kind_of(Establishment)
                assert establishments.first.invoked
              end
            end

            it 'should retrieve a hierarchy' do
              VCR.use_cassette('application.test_hierarchy') do
                app = SapiClient::Application.new(
                  'http://fsa-rp-test.epimorphics.net',
                  'test/fixtures/regulated-products/application.yaml'
                )
                hierarchy = app.instance.feed_category_hierarchy_hierarchy({}, :skos)
                _(hierarchy.roots.size).must_equal(5)
              end
            end
          end
        end
      end
    end
  end
end
