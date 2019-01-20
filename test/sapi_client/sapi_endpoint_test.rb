# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class SapiEndpointTest < Minitest::Test
    describe 'SapiEndpoint' do
      describe '#initialize' do
        it 'should reject a specification with no type' do
          -> { SapiClient::SapiEndpoint.new('', {}) }.must_raise SapiClient::Error
        end

        it 'should reject a specification with a non-permitted type' do
          -> { SapiClient::SapiEndpoint.new('', 'type' => 'womble') }.must_raise SapiClient::Error
        end

        it 'should accept a well-formed specification without raising' do
          SapiClient::SapiEndpoint.new('', 'type' => 'item')
        end
      end

      describe 'endpoint type' do
        it 'should correctly report the endpoint type' do
          ep = SapiClient::SapiEndpoint.new('', 'type' => 'item')
          assert ep.item_endpoint?
          refute ep.list_endpoint?

          ep = SapiClient::SapiEndpoint.new('', 'type' => 'list')
          refute ep.item_endpoint?
          assert ep.list_endpoint?
        end
      end

      describe 'base URL' do
        it 'should report the base URL that was passed' do
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', 'type' => 'item')
          ep.base_url.must_equal 'http://foo.bar'
        end
      end

      describe '#path' do
        it 'should return the relative URI path, as given' do
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', 'type' => 'item', 'url' => '/womble')
          ep.path.must_equal('/womble')
        end
      end

      describe '#url' do
        it 'should return the absolute URL' do
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', 'type' => 'item', 'url' => '/womble')
          ep.url.must_equal 'http://foo.bar/womble'
        end
      end
    end
  end
end
