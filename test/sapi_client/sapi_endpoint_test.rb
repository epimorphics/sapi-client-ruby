# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class SapiEndpointTest < Minitest::Test
    describe 'SapiEndpoint' do
      describe '#initialize' do
        it 'should reject a specification with no type' do
          -> { SapiClient::SapiEndpoint.new({}) }.must_raise SapiClient::Error
        end

        it 'should reject a specification with a non-permitted type' do
          -> { SapiClient::SapiEndpoint.new(type: 'womble') }.must_raise SapiClient::Error
        end

        it 'should accept a well-formed specification without raising' do
          SapiClient::SapiEndpoint.new(type: 'item')
        end
      end
    end
  end
end
