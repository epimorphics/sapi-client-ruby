# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

# Logger that simply captures the request and response
class CapturingLogger
  attr_reader :request, :response

  def log_request(req)
    @request = req
  end

  def log_response(resp)
    @response = resp
  end
end

# Pretend to include the Json Logger
module JsonRailsLogger
  REQUEST_ID = 'mock-thread-var'
end

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

      describe '#get_hierarchy' do
        it('should load a hierarchy from a hierarchy endpoint') do
          VCR.use_cassette('sapi_instance.get_hierarchy') do
            instance = SapiClient::Instance.new('http://fsa-rp-test.epimorphics.net')

            hierarchy = instance.get_hierarchy(
              'http://fsa-rp-test.epimorphics.net/regulated-products/id/feed-additives/category',
              { _all: true },
              :skos
            )

            _(hierarchy.roots.length).must_equal(5)
            _(hierarchy.roots[0].notation).must_equal('1')
            _(hierarchy.roots[0].children[0].notation).must_match(/1[a-z]/)
          end
        end
      end

      describe '#get_missing_item' do
        it 'should raise an error when fetching from a URL that returns 404' do
          VCR.use_cassette('sapi_instance.get_missing_item') do
            assert_raises(RuntimeError) do
              instance = SapiClient::Instance.new(base_url)
              instance.get_items("#{base_url}/business/id/establishment/womble", _limit: 1)
            end
          end
        end

        it 'should return an error-wrapped-JSON value when fetching from a URL that returns 404' do
          VCR.use_cassette('sapi_instance.get_missing_item') do
            instance = SapiClient::Instance.new(base_url)
            instance.get_items("#{base_url}/business/id/establishment/womble", _limit: 1)
          rescue RuntimeError => e
            _(e.status).must_equal 404
          end
        end
      end

      describe 'logging' do
        it 'should use a request logger to record request and responses' do
          VCR.use_cassette('sapi_instance.request_logger') do
            logger = mock('request_logger')
            logger.expects(:log_request).with(instance_of(Faraday::Request))
            logger.expects(:log_response).with(instance_of(Faraday::Response))

            instance = SapiClient::Instance.new(base_url)
            instance.request_logger = logger
            json = instance.get_json("#{base_url}/business/id/establishment", _limit: 1)
            _(json).must_be_kind_of Hash
          end
        end

        it 'should not log automatically if Rails is not defined' do
          instance = SapiClient::Instance.new(base_url)

          refute instance.send(:rails_logging?)
        end

        it 'should log automatically if Rails is in dev mode' do
          mock_env = mock('ruby-env')
          mock_env.expects(:production?).returns(false)

          mock_rails = Class.new(Object)
          mock_rails.define_singleton_method(:logger) { Object.new }
          mock_rails.define_singleton_method(:env) { mock_env }
          Object.const_set('Rails', mock_rails)

          instance = SapiClient::Instance.new(base_url)

          assert instance.send(:rails_logging?)
        ensure
          # clean-up the global `Rails` constant
          Object.send(:remove_const, 'Rails')
        end

        it 'should not log automatically if Rails is in production mode' do
          mock_env = mock('rails-env')
          mock_env.expects(:production?).returns(true)

          mock_config = mock('rails-config')
          mock_config.expects(:config).returns(OpenStruct.new)

          mock_rails = Class.new(Object)
          mock_rails.define_singleton_method(:logger) { Object.new }
          mock_rails.define_singleton_method(:env) { mock_env }
          mock_rails.define_singleton_method(:application) { mock_config }
          Object.const_set('Rails', mock_rails)

          instance = SapiClient::Instance.new(base_url)

          refute instance.send(:rails_logging?)
        ensure
          # clean-up the global `Rails` constant
          Object.send(:remove_const, 'Rails')
        end

        it 'should log automatically if Rails is in production mode but config is set' do
          mock_env = mock('rails-env')
          mock_env.expects(:production?).returns(true)

          mock_config = mock('rails-config')
          mock_config.expects(:config).returns(OpenStruct.new(sapi_client_log_api_calls: true)).at_least_once

          mock_rails = Class.new(Object)
          mock_rails.define_singleton_method(:logger) { Object.new }
          mock_rails.define_singleton_method(:env) { mock_env }
          mock_rails.define_singleton_method(:application) { mock_config }
          Object.const_set('Rails', mock_rails)

          instance = SapiClient::Instance.new(base_url)

          assert instance.send(:rails_logging?)
        ensure
          # clean-up the global `Rails` constant
          Object.send(:remove_const, 'Rails')
        end
      end

      describe '#resolve' do
        it 'should not attempt to resolve a resource that is not resolvable' do
          resource = mock('resource')
          resource.expects(:resolvable?).returns(false)

          instance = SapiClient::Instance.new(base_url)
          resolved_resource = instance.resolve(resource)
          _(resolved_resource).must_be_same_as(resource)
        end

        it 'should resolve a resource that is resolvable' do
          VCR.use_cassette('sapi_instance.resolve') do
            resource = mock('resource')
            resource.expects(:resolvable?).returns(true)
            resource.expects(:uri).returns('http://data.food.gov.uk/business/id/establishment/EHMQY4-DG9V0T-PTSDJH')

            instance = SapiClient::Instance.new(base_url)
            resolved_resource = instance.resolve(resource)

            _(resolved_resource.label).must_match(/nando/i)
          end
        end
      end

      describe 'request identification' do
        it 'should not pass along the `X-Request-ID` if not defined' do
          VCR.use_cassette('sapi_instance.request_id_no_header') do
            logger = CapturingLogger.new

            instance = SapiClient::Instance.new(base_url)
            instance.request_logger = logger
            json = instance.get_json("#{base_url}/business/id/establishment", _limit: 1)
            _(json).must_be_kind_of Hash

            headers = logger.request.headers
            _(headers.keys).wont_include('X-Request-ID')
          end
        end

        it 'should pass along the `X-Request-ID` if defined' do
          VCR.use_cassette('sapi_instance.request_id_no_header') do
            Thread.current[JsonRailsLogger::REQUEST_ID] = 'Wimbledon-99-bus'
            logger = CapturingLogger.new

            instance = SapiClient::Instance.new(base_url)
            instance.request_logger = logger
            json = instance.get_json("#{base_url}/business/id/establishment", _limit: 1)
            _(json).must_be_kind_of Hash

            headers = logger.request.headers
            _(headers.keys).must_include('X-Request-ID')
            _(headers['X-Request-ID']).must_equal('Wimbledon-99-bus')
          ensure
            Thread.current[JsonRailsLogger::REQUEST_ID] = nil
          end
        end
      end
    end
  end
end
