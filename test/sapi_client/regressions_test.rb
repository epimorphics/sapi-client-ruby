# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class RegressionsTest < Minitest::Test
    describe 'Regression tests' do
      describe 'https://github.com/epimorphics/sapi-client-ruby/issues/44' do
        [
          'test/fixtures/cbd_api/application.yaml',
          'test/fixtures/cbd_api/endpointSpecs'
        ].each do |spec_file_or_dir|
          describe "#with {spec_file_or_dir}" do
            let(:spec) { 'test/fixtures/cbd_api/application.yaml' }
            let(:base_url) { 'https://fsa-cbd-test.epimorphics.net' }

            it 'should return a list containing SapiResource items' do
              app = SapiClient::Application.new(base_url, spec)
              inst = app.instance

              VCR.use_cassette('regression_tests.issue-44') do
                listings = inst.listing_list(_limit: 1)

                _(listings.first).must_be_kind_of SapiClient::SapiResource
              end
            end
          end
        end
      end
    end
  end
end
