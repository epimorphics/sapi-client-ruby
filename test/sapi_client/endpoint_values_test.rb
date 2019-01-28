# frozen-string-literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class EndpointValuesTest < Minitest::Test
    describe 'EndpointValues' do
      describe '#initialize' do
        it 'should store the initialization parameters' do
          evs = SapiClient::EndpointValues.new(:mock_instance, :mock_endpoint, mock_param: true)
          evs.instance.must_equal(:mock_instance)
          evs.endpoint_name.must_equal(:mock_endpoint)
          evs.params[:mock_param].must_equal true
        end

        it 'should allow a default set of options' do
          evs = SapiClient::EndpointValues.new(:mock_instance, :mock_endpoint)
          evs.params.must_be_empty
        end
      end
    end

    describe '#limit' do
      it 'should set the offset' do
        evs = SapiClient::EndpointValues.new(:mock_instance, :mock_endpoint)
        evs.limit(999)
        evs.params[:_limit].must_equal 999
      end
    end

    describe '#offset' do
      it 'should set the offset' do
        evs = SapiClient::EndpointValues.new(:mock_instance, :mock_endpoint)
        evs.offset(999)
        evs.params[:_offset].must_equal 999
      end
    end

    describe '#sort' do
      it 'should set the sort parameter' do
        evs = SapiClient::EndpointValues.new(:mock_instance, :mock_endpoint)
        evs.sort('womble')
        evs.params[:_sort].must_equal 'womble'
      end
    end

    describe '#to_a' do
      let(:spec) { 'test/fixtures/application.yaml' }
      let(:base_url) { 'http://localhost:8080' }

      it 'should invoke the endpoint with the parameters' do
        app = SapiClient::Application.new(base_url, spec)
        inst = app.instance

        VCR.use_cassette('endpoint_values.test_to_a') do
          evs = SapiClient::EndpointValues.new(inst, :establishment_list)
          evs.limit(1)
          establishments = evs.to_a
          establishments.must_be_kind_of(Array)
          establishments.length.must_equal(1)
        end
      end
    end
  end
end
