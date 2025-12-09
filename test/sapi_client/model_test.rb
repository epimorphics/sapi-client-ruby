# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class ModelTest < Minitest::Test
    describe 'regulated product applications model' do
      before do
        @app = SapiClient::Application.new(
          'https://fsa-rpa-dev.epimorphics.net',
          'test/fixtures/rp-applications/application.yaml'
        )
      end

      describe 'application with missing property' do
        it 'shouldn\'t raise missing method exception on optional, missing property' do
          inst = @app.instance
          VCR.use_cassette('model_test.application_missing_property') do
            item = inst.application_item({ id: 'RP-3099' })[0]
            _(item.notation).must_equal 'RP-3099'
            _(item.path_first('marketingName')).must_be_nil
            _(item.marketingName).must_be_nil
          end
        end
      end
    end
  end
end
