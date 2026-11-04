# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

class CommonResource
  def initialize(_ignored); end
end

class WombleResource < CommonResource
end

module SapiClient
  class ResourceWrapperTest < Minitest::Test
    describe 'ResourceWrapper' do
      describe '#de_uri' do
        it 'should convert a URI string to a symbol' do
          _(ResourceWrapper.de_uri('http://wimbledon.com/womble')).must_equal(:womble)
        end

        it 'should convert a non-symbol to symbol' do
          _(ResourceWrapper.de_uri('womble')).must_equal(:womble)
        end

        it 'should not change an existing symbol' do
          _(ResourceWrapper.de_uri(:womble)).must_equal(:womble)
        end
      end

      describe('#wrapper_class_constant') do
        it 'should find a class constant if it exists' do
          _(ResourceWrapper.wrapper_class_constant(:WombleResource)).must_equal(WombleResource)
        end

        it 'should return nil if no class constant exists' do
          _(ResourceWrapper.wrapper_class_constant(:Wimbledon)).must_be_nil
        end
      end

      describe('#find_wrapper_type') do
        it 'should find the first matching wrapper type' do
          _(
            ResourceWrapper
            .find_wrapper_type(%i[Wimbledon WombleResource Array])
          ).must_equal(WombleResource)
        end

        it 'should find the most specific matching wrapper type' do
          _(
            ResourceWrapper
              .find_wrapper_type(%i[CommonResource Wimbledon WombleResource Array])
          ).must_equal(WombleResource)
        end

        it 'should return nil if a wrapper cannot be found' do
          _(
            ResourceWrapper
            .find_wrapper_type([:Wimbledon])
          ).must_equal(SapiClient::SapiResource)
        end
      end
    end

    describe('#wrap_resource') do
      it 'should use the explicit wrapper if given' do
        _(
          ResourceWrapper
          .wrap_resource(nil, wrapper: :WombleResource)
        ).must_be_kind_of(WombleResource)

        _(
          ResourceWrapper
          .wrap_resource(nil, wrapper: 'http://wimbledon.com/WombleResource')
        ).must_be_kind_of(WombleResource)
      end

      it 'should use the resource types method if defined' do
        resource = mock('resource')
        resource.expects(:types).returns(['http://wimbledon.com/WombleResource'])

        _(ResourceWrapper.wrap_resource(resource)).must_be_kind_of(WombleResource)
      end

      it 'should use the declared type of a resource to find the wrapper' do
        original_names = SapiClient::SapiResource.model_class_names
        SapiClient::SapiResource.model_class_names = {
          'http://wimbledon.com/WombleResource' => 'WombleResource'
        }
        begin
          resource = SapiClient::SapiResource.new('@id' => 'http://wimbledon.com/tobermory')
          resource.declared_type = 'http://wimbledon.com/WombleResource'

          _(ResourceWrapper.wrap_resource(resource)).must_be_kind_of(WombleResource)
        ensure
          SapiClient::SapiResource.model_class_names = original_names
        end
      end
    end

    describe('#type_string') do
      it 'should normalise a URI string' do
        _(ResourceWrapper.type_string('http://wimbledon.com/WombleResource'))
          .must_equal('http://wimbledon.com/WombleResource')
      end

      it 'should extract the id from a resource' do
        resource = SapiClient::SapiResource.new('@id' => 'http://wimbledon.com/WombleResource')
        _(ResourceWrapper.type_string(resource)).must_equal('http://wimbledon.com/WombleResource')
      end

      it 'should extract the id from a hash with string or symbol keys' do
        _(ResourceWrapper.type_string({ '@id' => 'http://wimbledon.com/WombleResource' }))
          .must_equal('http://wimbledon.com/WombleResource')
        _(ResourceWrapper.type_string({ :@id => 'http://wimbledon.com/WombleResource' }))
          .must_equal('http://wimbledon.com/WombleResource')
      end
    end

    describe('#wrapper_class_name') do
      it 'should use the declared model class name when available' do
        original_names = SapiClient::SapiResource.model_class_names
        SapiClient::SapiResource.model_class_names = {
          'http://wimbledon.com/womble' => 'WombleResource'
        }
        begin
          _(ResourceWrapper.wrapper_class_name('http://wimbledon.com/womble'))
            .must_equal('WombleResource')
        ensure
          SapiClient::SapiResource.model_class_names = original_names
        end
      end

      it 'should fall back to the final URI segment when not declared' do
        original_names = SapiClient::SapiResource.model_class_names
        SapiClient::SapiResource.model_class_names = {}
        begin
          _(ResourceWrapper.wrapper_class_name('http://wimbledon.com/WombleResource'))
            .must_equal(:WombleResource)
        ensure
          SapiClient::SapiResource.model_class_names = original_names
        end
      end
    end
  end
end
