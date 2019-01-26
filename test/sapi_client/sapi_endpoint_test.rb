# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

class MockWomble; end

module SapiClient
  class SapiEndpointTest < Minitest::Test
    describe 'SapiEndpoint' do
      describe '#initialize' do
        it 'should reject a specification with no type' do
          -> { SapiClient::SapiEndpoint.new('', {}, {}) }.must_raise SapiClient::Error
        end

        it 'should reject a specification with a non-permitted type' do
          -> { SapiClient::SapiEndpoint.new('', {}, 'type' => 'womble') }.must_raise SapiClient::Error
        end

        it 'should accept a well-formed specification without raising' do
          SapiClient::SapiEndpoint.new('', {}, 'type' => 'item')
        end
      end

      describe 'endpoint type' do
        it 'should correctly report the endpoint type' do
          ep = SapiClient::SapiEndpoint.new('', {}, 'type' => 'item')
          assert ep.item_endpoint?
          refute ep.list_endpoint?

          ep = SapiClient::SapiEndpoint.new('', {}, 'type' => 'list')
          refute ep.item_endpoint?
          assert ep.list_endpoint?
        end
      end

      describe 'name' do
        it 'should convert the endpoint name to Ruby conventions' do
          SapiClient::SapiEndpoint
            .new('', {}, 'type' => 'item', 'name' => 'establishmentList')
            .name
            .must_equal('establishment_list')
        end
      end

      describe 'base URL' do
        it 'should report the base URL that was passed' do
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', {}, 'type' => 'item')
          ep.base_url.must_equal 'http://foo.bar'
        end
      end

      describe '#path' do
        it 'should return the relative URI path, as given' do
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', {}, 'type' => 'item', 'url' => '/womble')
          ep.raw_path.must_equal('/womble')
        end

        it 'should not perform substitutions if no path variables are defined' do
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', {}, 'type' => 'item', 'url' => '/womble')
          ep.path({}).must_equal('/womble')
        end

        it 'should perform path variable substitutions' do
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', {}, 'type' => 'item', 'url' => '/womble/{__id}')
          ep.path('id' => 42).must_equal('/womble/42')
        end

        it 'should raise an error if a path variable substitution is missing' do
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', {}, 'type' => 'item', 'url' => '/womble/{__id}')
          -> { ep.path(ID: 42) }.must_raise(SapiClient::Error)
        end
      end

      describe '#url' do
        it 'should return the absolute URL' do
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', {}, 'type' => 'item', 'url' => '/womble')
          ep.url({}).must_equal 'http://foo.bar/womble'
        end
      end

      describe '#path_variables' do
        it 'should extract a list of no path variables if none are present' do
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', {}, 'type' => 'item', 'url' => '/womble')
          ep.path_variables('').must_equal []
        end

        it 'should extract a list of the path variables' do
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', {}, 'type' => 'item', 'url' => '/womble/{__id}')
          ep.path_variables('/womble/{__id}').must_equal [{ substitution: '{__id}', name: 'id' }]

          ep = SapiClient::SapiEndpoint.new('http://foo.bar', {}, 'type' => 'item', 'url' => '/womble/{i_d}')
          ep.path_variables('/womble/{i_d}').must_equal [{ substitution: '{i_d}', name: 'i_d' }]
        end
      end

      describe '#view_names' do
        it 'should return the names of the views for this endpoint' do
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', {}, 'type' => 'item', 'views' => { 'default' => 'a', 'womble' => 'b' })
          ep.view_names.length.must_equal 2
          ep.view_names.must_include 'default'
          ep.view_names.must_include 'womble'
        end
      end

      describe '#view' do
        it 'should look up a view by name' do
          mock_views = { 'womble' => SapiClient::View.new('name' => 'wombleView') }
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', mock_views, 'type' => 'item', 'views' => { 'default' => 'womble' })
          v = ep.view('default')
          v.name.must_equal 'wombleView'
        end

        it 'should return nil if a view is not found' do
          mock_views = { 'womble' => SapiClient::View.new('name' => 'wombleView') }
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', mock_views, 'type' => 'item', 'views' => { 'default' => 'womble' })
          v = ep.view('not_a_view')
          v.must_be_nil
        end
      end

      describe '#resource_type' do
        it 'should report the default resource type' do
          mock_views = { 'womble' => SapiClient::View.new('name' => 'wombleView', 'view' => { 'class' => ':Womble' }) }
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', mock_views, 'type' => 'item', 'views' => { 'default' => 'womble' })
          ep.resource_type.must_equal('Womble')
        end
      end

      describe '#resource_type_wrapper_class' do
        it 'should report the wrapper class for the resource type, if defined' do
          mock_views = { 'womble' => SapiClient::View.new('name' => 'wombleView', 'view' => { 'class' => ':MockWomble' }) }
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', mock_views, 'type' => 'item', 'views' => { 'default' => 'womble' })
          rt_cls = ep.resource_type_wrapper_class
          rt_cls.must_be_kind_of(Class)
          rt_cls.must_equal MockWomble
        end

        it 'should return nil with no error if there is no wrapper class defined' do
          mock_views = { 'womble' => SapiClient::View.new('name' => 'wombleView', 'view' => { 'class' => ':Wombles' }) }
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', mock_views, 'type' => 'item', 'views' => { 'default' => 'womble' })
          rt_cls = ep.resource_type_wrapper_class
          rt_cls.must_be_nil
        end
      end

      describe '#bind' do
        it 'should bind values to var names' do
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', {}, 'type' => 'item', 'url' => '/womble/{__id}/clan/{clan}')

          options = {}
          ep.bind(options, [42, 'wimbledon'])

          options.must_equal('id' => 42, 'clan' => 'wimbledon')
        end

        it 'should raise if vars and values arrays are different lengths in bind' do
          ep = SapiClient::SapiEndpoint.new('http://foo.bar', {}, 'type' => 'item', 'url' => '/womble/{__id}/clan/{clan}')

          options = {}
          -> { ep.bind(options, [42]) }.must_raise(SapiClient::Error)
        end
      end
    end
  end
end
