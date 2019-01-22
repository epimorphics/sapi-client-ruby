# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class SapiEndpointTest < Minitest::Test
    describe 'Instance' do
      let(:base_url) { 'http://localhost:8080' }

      describe '#get_json' do
        it 'should load JSON formatted data on request' do
          VCR.use_cassette('sapi_instance.get_json') do
            instance = SapiClient::Instance.new
            json = instance.get_json("#{base_url}/food-businesses/establishment", _limit: 1)
            json.must_be_kind_of Hash
            json['items'].must_be_kind_of Array
            json['items'].length.must_equal 1
          end
        end
      end

      describe '#get_items' do
        it 'should wrap items loaded from an endpoint' do
          VCR.use_cassette('sapi_instance.get_items') do
            mock_wrapper = Minitest::Mock.new
            mock_wrapper.expect(:new, :wrapped_item, [Hash])

            instance = SapiClient::Instance.new
            items = instance.get_items("#{base_url}/food-businesses/establishment", wrapper: mock_wrapper, _limit: 1)
            items.must_equal [:wrapped_item]
          end
        end
      end
    end
  end
end
