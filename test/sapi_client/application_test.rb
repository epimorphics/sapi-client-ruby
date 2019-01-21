# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class ApplicationTest < Minitest::Test
    describe 'Application' do
      let(:spec) { 'test/fixtures/application.yaml' }

      describe '#initialize' do
        it 'should load the application specification given' do
          app = SapiClient::Application.new(spec)
          app.specification.must_be_kind_of Hash
        end

        it 'should raise an error if the spec file does not exist' do
          -> { SapiClient::Application.new('wimbledon/wombles.yaml') }.must_raise(SapiClient::Error)
        end
      end

      describe '#configuration' do
        it 'should report the application configuration' do
          app = SapiClient::Application.new(spec)
          app.configuration.must_be_kind_of Hash
          assert app.configuration.key?('loadSpecPath')
        end
      end

      describe '#endpoint_spec_files' do
        it 'should return the names of all of the endpoint specification files' do
          app = SapiClient::Application.new(spec)
          file_names = app.endpoint_spec_files
          file_names.length.must_be :>, 5
          file_names.must_include('test/fixtures/endpointSpecs/establishment.yaml')
        end
      end
    end
  end
end
