# frozen_string_literal: true

require 'test_helper'

module SapiClient
  class VersionTest < Minitest::Test
    describe 'this library' do
      it 'should have a version number' do
        _(::SapiClient::VERSION).wont_be_nil
      end
    end
  end
end
