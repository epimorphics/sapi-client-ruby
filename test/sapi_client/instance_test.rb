# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class SapiEndpointTest < Minitest::Test
    describe 'Instance' do
      let(:base_url) { "http://localhost:#{sapi_api_port}" }

      describe '#base_url' do
        it 'should return the base URL' do
          _(
            SapiClient::Instance
            .new('http://foo.bar')
            .base_url
          ).must_equal('http://foo.bar')
        end
      end

      describe '#get_json' do
        it 'should load JSON formatted data on request' do
          VCR.use_cassette('sapi_instance.get_json') do
            instance = SapiClient::Instance.new(base_url)
            json = instance.get_json("#{base_url}/business/id/establishment", _limit: 1)
            _(json).must_be_kind_of Hash
            _(json['items']).must_be_kind_of Array
            _(json['items'].length).must_equal 1
          end
        end

        it 'should allow multiple-value filters in a request' do
          VCR.use_cassette('sapi_instance.get_json') do
            instance = SapiClient::Instance.new(base_url)
            json = instance.get_json(
              "#{base_url}/business/id/establishment",
              _limit: 10,
              establishmentType: [
                'http://data.food.gov.uk/codes/business/establishment/RC-HG',
                'http://data.food.gov.uk/codes/business/establishment/RC-SC'
              ]
            )
            _(json).must_be_kind_of Hash
            _(json['items']).must_be_kind_of Array
            _(json['items'].length).must_equal 10
          end
        end
      end

      describe '#get_items' do
        it 'should wrap items loaded from an endpoint' do
          VCR.use_cassette('sapi_instance.get_items') do
            mock_wrapper = Minitest::Mock.new
            mock_wrapper.expect(:new, :wrapped_item, [Hash])

            instance = SapiClient::Instance.new(base_url)
            items = instance.get_items("#{base_url}/business/id/establishment", wrapper: mock_wrapper, _limit: 1)
            _(items).must_equal [:wrapped_item]
          end
        end
      end

      describe '#get_missing_item' do
        it 'should return a wrapped-JSON value when fetching from a URL that returns 404' do
          VCR.use_cassette('sapi_instance.get_missing_item') do
            instance = SapiClient::Instance.new(base_url)
            items = instance.get_items("#{base_url}/business/id/establishment/womble", _limit: 1)
            _(items).must_be_kind_of Array
            _(items.length).must_equal 1
            _(items.first['status']).must_equal '404'
          end
        end
      end

      describe 'request_logger' do
        it 'should use a request logger to record request and responses' do
          VCR.use_cassette('sapi_instance.request_logger') do
            logger = mock('request_logger')
            logger.expects(:log_response).with(instance_of(Faraday::Response))

            instance = SapiClient::Instance.new(base_url)
            instance.request_logger = logger
            json = instance.get_json("#{base_url}/business/id/establishment", _limit: 1)
            _(json).must_be_kind_of Hash
          end
        end
      end

      describe '#resolve' do
        it 'should not attempt to resolve a resource that is not resolvable' do
          resource = mock('resource')
          resource.expects(:'resolvable?').returns(false)

          instance = SapiClient::Instance.new(base_url)
          resolved_resource = instance.resolve(resource)
          _(resolved_resource).must_be_same_as(resource)
        end

        it 'should resolve a resource that is resolvable' do
          VCR.use_cassette('sapi_instance.resolve') do
            resource = mock('resource')
            resource.expects(:'resolvable?').returns(true)
            resource.expects(:uri).returns('http://data.food.gov.uk/business/id/establishment/EHMQY4-DG9V0T-PTSDJH')

            instance = SapiClient::Instance.new(base_url)
            resolved_resource = instance.resolve(resource)

            _(resolved_resource.label).must_match(/nando/i)
          end
        end
      end
    end
  end
end
