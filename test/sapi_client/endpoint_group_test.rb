# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class EndpointGroupTest < Minitest::Test
    describe 'EndpointGroup' do
      let(:base_url) { 'http://foo.bar' }
      let(:spec_file) { 'test/fixtures/endpointSpecs/establishment.yaml' }

      describe '#initialize' do
        it 'should be initialized by loading a YAML spec file' do
          es = SapiClient::EndpointGroup.new(base_url, spec_file)
          es.specification.must_be_kind_of Array
        end

        it 'should raise if the path to the endpoint specification cannot be found' do
          lambda {
            SapiClient::EndpointGroup.new(base_url, 'test/fixtures/endpointSpecs/womble.yaml')
          }.must_raise(SapiClient::Error)
        end
      end

      describe '#endpoints' do
        it 'should return an array of all of the endpoints in the specification' do
          es = SapiClient::EndpointGroup.new(base_url, spec_file)
          eps = es.endpoints

          eps.length.must_equal 2
          eps.first.must_be_kind_of(SapiClient::SapiEndpoint)
        end
      end

      describe '#views' do
        it 'should collate the views in an endpoint spec' do
          es = SapiClient::EndpointGroup.new(base_url, spec_file)
          ev = es.views

          ev.keys.length.must_equal 3
          ev.keys.each do |key|
            ev[key].name.must_equal key
          end
        end
      end
    end
  end
end
