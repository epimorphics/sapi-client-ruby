# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class EndpointValuesTest < Minitest::Test
    describe 'EndpointValues' do
      describe '#initialize' do
        it 'should store the initialization parameters' do
          evs = SapiClient::EndpointValues.new(:mock_instance, :mock_endpoint, mock_param: true)
          _(evs.instance).must_equal(:mock_instance)
          _(evs.endpoint_name).must_equal(:mock_endpoint)
          _(evs.params[:mock_param]).must_equal true
        end

        it 'should allow a default set of options' do
          evs = SapiClient::EndpointValues.new(:mock_instance, :mock_endpoint)
          _(evs.params).must_be_empty
        end
      end
    end

    describe '#limit' do
      it 'should set the offset' do
        evs = SapiClient::EndpointValues.new(:mock_instance, :mock_endpoint)
        evs.limit(999)
        _(evs.params[:_limit]).must_equal 999
      end
    end

    describe '#offset' do
      it 'should set the offset' do
        evs = SapiClient::EndpointValues.new(:mock_instance, :mock_endpoint)
        evs.offset(999)
        _(evs.params[:_offset]).must_equal 999
      end
    end

    describe '#sort' do
      it 'should set the sort parameter' do
        evs = SapiClient::EndpointValues.new(:mock_instance, :mock_endpoint)
        evs.sort('womble')
        _(evs.params[:_sort]).must_equal 'womble'
      end
    end

    describe '#to_a' do
      [
        'test/fixtures/regulated-products/application.yaml',
        'test/fixtures/regulated-products/endpointSpecs'
      ].each do |spec_file_or_dir|
        let(:spec) { 'test/fixtures/regulated-products/application.yaml' }
        let(:base_url) { 'https://fsa-dev-rp.epimorphics.net' }

        describe "#with #{spec_file_or_dir}" do
          it 'should invoke the endpoint with the parameters' do
            app = SapiClient::Application.new(base_url, spec)
            inst = app.instance

            VCR.use_cassette('endpoint_values.test_to_a') do
              evs = SapiClient::EndpointValues.new(inst, :feed_additives_list)
              evs.limit(1)
              additives = evs.to_a
              _(additives).must_be_kind_of(Array)
              _(additives.length).must_equal(1)
            end
          end
        end
      end
    end
  end
end
