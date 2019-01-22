# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class SapiEndpointTest < Minitest::Test
    describe 'View' do
      let(:spec_fixture) do
        {
          'name' => 'authorityDefaultView',
          'type' => 'view',
          'view' => {
            'class' => ':Authority',
            'projection' => '*'
          }
        }
      end

      describe '#initialize' do
        it 'should save the specification' do
          SapiClient::View.new(test_double: 42).specification[:test_double].must_equal 42
        end
      end

      describe '#resource_type' do
        it 'should determine the resource type correctly' do
          SapiClient::View
            .new(spec_fixture)
            .resource_type
            .must_equal 'Authority'
        end
      end
    end
  end
end
