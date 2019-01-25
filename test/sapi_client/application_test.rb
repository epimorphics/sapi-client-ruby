# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class ApplicationTest < Minitest::Test
    describe 'Application' do
      let(:spec) { 'test/fixtures/application.yaml' }
      let(:base_url) { 'http://localhost:8080' }

      describe '#initialize' do
        it 'should load the application specification given' do
          app = SapiClient::Application.new(base_url, spec)
          app.specification.must_be_kind_of Hash
        end

        it 'should raise an error if the spec file does not exist' do
          -> { SapiClient::Application.new(base_url, 'wimbledon/wombles.yaml') }.must_raise(SapiClient::Error)
        end

        it 'should store the base URL' do
          app = SapiClient::Application.new(base_url, spec)
          app.base_url.must_equal base_url
        end
      end

      describe '#configuration' do
        it 'should report the application configuration' do
          app = SapiClient::Application.new(base_url, spec)
          app.configuration.must_be_kind_of Hash
          assert app.configuration.key?('loadSpecPath')
        end
      end

      describe '#endpoint_group_files' do
        it 'should return the names of all of the endpoint specification files' do
          app = SapiClient::Application.new(base_url, spec)
          file_names = app.endpoint_group_files
          file_names.length.must_be :>, 5
          file_names.must_include('test/fixtures/endpointSpecs/establishment.yaml')
        end
      end

      describe '#endpoints' do
        it 'should return a list of all of the endpoint specification objects' do
          app = SapiClient::Application.new(base_url, spec)
          eps = app.endpoints
          eps.must_be_kind_of Array
          eps.length.must_be :>, 5

          eps.map(&:raw_path).must_include '/food-businesses/establishment'
        end
      end

      describe '#instance' do
        it 'should create an instance with methods corresponding to endpoints' do
          app = SapiClient::Application.new(base_url, spec)
          inst = app.instance
          methods = inst.public_methods
          methods.must_include(:establishment_list)
          methods.must_include(:establishment_list_spec)
        end
      end
    end
  end
end
