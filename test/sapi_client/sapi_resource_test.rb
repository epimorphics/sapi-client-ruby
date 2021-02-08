# frozen-string-literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class SapiResourceTest < Minitest::Test
    describe 'Resource' do
      describe '#initialize' do
        it 'should construct a resource from a Hash' do
          r = SapiClient::SapiResource.new(womble: 'tobermory')
          _(r.resource[:womble]).must_equal('tobermory')
        end

        it 'should symbolize keys' do
          r = SapiClient::SapiResource.new('womble' => 'tobermory')
          _(r.resource[:womble]).must_equal('tobermory')
        end

        it 'should treat a string as a URI' do
          r = SapiClient::SapiResource.new('http://wimbledon.org.uk/womble')
          _(r.resource[:@id]).must_equal('http://wimbledon.org.uk/womble')
        end
      end

      describe 'identity' do
        it 'should use URIs to denote equality of resources' do
          r0 = SapiClient::SapiResource.new('@id' => 'http://wimbledon.org/tobermory')
          r1 = SapiClient::SapiResource.new('@id' => 'http://wimbledon.org/uncle-bulgaria')
          r2 = SapiClient::SapiResource.new('@id' => 'http://wimbledon.org/tobermory')

          refute r0.equal?(r1)
          assert r0.equal?(r2)
        end

        it 'should calculate a hash based on the identity value' do
          s = 'http://wimbledon.org/tobermory'
          _(SapiClient::SapiResource.new('@id' => s).hash).must_equal(s.hash)

          n = 'Tobermory'
          _(SapiClient::SapiResource.new('@value' => n).hash).must_equal(n.hash)
        end
      end

      describe '#path_first' do
        it 'should traverse a path and find the value' do
          r = SapiClient::SapiResource.new(a: { b: 42 })
          _(r.path_first('a.b')).must_equal(42)
        end

        it 'should select the first terminal value' do
          r = SapiClient::SapiResource.new(a: { b: [42, 100] })
          _(r.path_first('a.b')).must_equal(42)
        end

        it 'should select the first value along the path' do
          r = SapiClient::SapiResource.new(a: { b: [{ c: 42 }, { c: 100 }] })
          _(r.path_first('a.b.c')).must_equal(42)
        end

        it 'should select the first value along the path when the outer is an array' do
          r = SapiClient::SapiResource.new(a: [{ c: 42 }, { c: 100 }])
          _(r.path_first('a.c')).must_equal(42)
        end

        it 'should select the first value along the path when non-symbol keys are used' do
          r = SapiClient::SapiResource.new(a: [{ 'b' => { c: 42 } }, { 'b' => { c: 100 } }])
          _(r.path_first('a.b.c')).must_equal(42)
        end

        it 'should select the first value along the path when @value is used' do
          r = SapiClient::SapiResource.new(a: [{ '@value': 42 }, { '@value': 100 }])
          _(r.path_first('a')).must_equal(42)
        end

        it 'should return nil if the path does not match' do
          r = SapiClient::SapiResource.new(a: { b: [{ c: 42 }, { c: 100 }] })
          _(r.path_first('a.d.c')).must_be_nil
        end

        it 'should recognise [] as an alias' do
          r = SapiClient::SapiResource.new(a: { b: [{ c: 42 }, { c: 100 }] })
          _(r['a.b.c']).must_equal(42)
        end
      end

      describe '#path_all' do
        it 'should return an array' do
          r = SapiClient::SapiResource.new(a: { b: 42 })
          _(r.path_all('a.b')).must_equal([42])
        end

        it 'should return all terminal values' do
          r = SapiClient::SapiResource.new(a: { b: [42, 100] })
          _(r.path_all('a.b')).must_equal([42, 100])
        end

        it 'should select all values along the path' do
          r = SapiClient::SapiResource.new(a: { b: [{ c: 42 }, { c: 100 }] })
          _(r.path_all('a.b.c')).must_equal([42, 100])
        end

        it 'should filter nil values along the path' do
          r = SapiClient::SapiResource.new(a: { b: [{ c: { d: 42 } }, { c: { d: 100 } }, { c: 999 }] })
          _(r.path_all('a.b.c.d')).must_equal([42, 100])
        end
      end

      describe 'type tests' do
        it 'should distinguish resources and values' do
          assert SapiClient::SapiResource.new(a: 42).resource?
          refute SapiClient::SapiResource.new(a: 42).value?

          refute SapiClient::SapiResource.new('@value' => 42).resource?
          assert SapiClient::SapiResource.new('@value' => 42).value?
        end

        it 'should identify a typed value' do
          fixture = SapiClient::SapiResource.new('@value' => 42, '@type' => 'http://test/Type')
          assert fixture.value?
          assert fixture.typed_value?
        end

        it 'should identify a lang-tagged value' do
          assert SapiClient::SapiResource.new('@value' => 'Tobermory', '@language' => 'en-wimbledon').value?
          assert SapiClient::SapiResource.new('@value' => 'Tobermory', '@language' => 'en-wimbledon').lang_tagged_value?
        end
      end

      describe '#uri' do
        it 'should return the URI if there is one' do
          r = SapiClient::SapiResource.new('@id' => 'http://wimbledon.org/common')
          _(r.uri).must_equal 'http://wimbledon.org/common'
        end

        it 'should nil if the resource has no URI' do
          r = SapiClient::SapiResource.new(a: { b: 42 })
          _(r.uri).must_be_nil
        end

        it 'should return nil for the URI slug for no URI' do
          _(
            SapiClient::SapiResource
            .new({})
            .uri_slug
          ).must_be_nil
        end

        it 'should return nil for the URI slug for URI with trailing `/`' do
          _(
            SapiClient::SapiResource
            .new('@id' => 'http://wimbledon.org/common/')
            .uri_slug
          ).must_be_nil
        end

        it 'should return the URI slug for a normal URI' do
          _(
            SapiClient::SapiResource
            .new('@id' => 'http://wimbledon.org/common')
            .uri_slug
          ).must_equal 'common'
        end

        it 'should return the URI slug for an fragment URI' do
          _(
            SapiClient::SapiResource
            .new('@id' => 'http://wimbledon.org/common#ground')
            .uri_slug
          ).must_equal 'ground'
        end
      end

      describe '#types' do
        it 'should return an array of the a single type' do
          r = SapiClient::SapiResource.new(type: { '@id' => 'http://wimbledon.org/Womble' })
          _(r.types.map(&:uri)).must_equal(['http://wimbledon.org/Womble'])
        end

        it 'should return an array of the types' do
          r = SapiClient::SapiResource.new(type: [{ '@id' => 'http://wimbledon.org/Womble' }, { '@id' => 'http://wimbledon.org/Testing' }])
          _(r.types.map(&:uri)).must_equal(['http://wimbledon.org/Womble', 'http://wimbledon.org/Testing'])
        end

        it 'should allow the types to be tested for a specific value' do
          r = SapiClient::SapiResource.new(type: [{ '@id' => 'http://wimbledon.org/Womble' }, { '@id' => 'http://wimbledon.org/Testing' }])

          assert r.type?('http://wimbledon.org/Womble')
          refute r.type?('http://moon.org/Clanger')
        end

        it 'should not error if a resource has no types' do
          r = SapiClient::SapiResource.new({})
          refute r.type?('http://wimbledon.org/Womble')
        end
      end

      describe '#value_of' do
        it 'should return the value of the given path' do
          r = SapiClient::SapiResource.new(a: { b: { '@value' => 42 } })
          _(r.value_of('a.b')).must_equal 42

          r = SapiClient::SapiResource.new(a: { b: 999 })
          _(r.value_of('a.b')).must_equal 999
        end

        it 'should return the value_of self if no path is given' do
          _(
            SapiClient::SapiResource
            .new('@value' => 'womble')
            .value_of
          ).must_equal 'womble'
        end
      end

      describe '#date' do
        it 'should interpret a date value' do
          _(
            SapiClient::SapiResource
            .new('@value' => '2019-01-27')
            .date
            .year
          ).must_equal 2019
        end
      end

      describe 'language handling' do
        let(:fixture) do
          [{ '@value' => 'untagged' }, { '@value' => 'EN', '@language' => 'en' }, { '@value' => 'WM', '@language' => 'womble' }]
        end

        it 'should identify the default langauage' do
          assert SapiClient::SapiResource.new(foo: fixture).default_lang
        end

        it 'should pick the specified language' do
          _(
            SapiClient::SapiResource
            .new(foo: fixture)
            .pick_value_by_language('foo', lang: 'en')
          ).must_equal('EN')
          _(
            SapiClient::SapiResource
            .new(foo: fixture)
            .pick_value_by_language('foo', lang: 'womble')
          ).must_equal('WM')
        end

        it 'should pick an untagged value if the pref lang is not available' do
          _(
            SapiClient::SapiResource
            .new(foo: fixture)
            .pick_value_by_language('foo', lang: 'fr')
          ).must_equal('untagged')
        end

        it 'should not pick a default-lang value if the pref lang is not available' do
          fixture1 = fixture.reject { |value| value['@value'] == 'untagged' }
          _(
            SapiClient::SapiResource
            .new(foo: fixture1)
            .pick_value_by_language('foo', lang: 'fr')
          ).must_be_nil
        end

        it 'should pick the default language if there is no specified choice' do
          _(
            SapiClient::SapiResource
            .new(foo: fixture)
            .pick_value_by_language('foo', lang: nil)
          ).must_equal('EN')
        end
      end

      describe '#name' do
        let(:fixture) do
          [{ '@value' => 'untagged' }, { '@value' => 'EN', '@language' => 'en' }, { '@value' => 'WM', '@language' => 'womble' }]
        end

        it 'should pick out the name with the given language' do
          _(
            SapiClient::SapiResource
            .new(name: fixture)
            .name(lang: 'en')
          ).must_equal('EN')
          _(
            SapiClient::SapiResource
            .new(name: fixture)
            .name(lang: 'womble')
          ).must_equal('WM')
        end

        it 'should pick out the name with the default language if not otherwise specified' do
          _(
            SapiClient::SapiResource
            .new(name: fixture)
            .name
          ).must_equal('EN')
        end
      end

      describe '#label' do
        let(:fixture) do
          [{ '@value' => 'untagged' }, { '@value' => 'EN', '@language' => 'en' }, { '@value' => 'WM', '@language' => 'womble' }]
        end

        it 'should pick out the label with the given language' do
          _(
            SapiClient::SapiResource
            .new(label: fixture)
            .label(lang: 'en')
          ).must_equal('EN')
          _(
            SapiClient::SapiResource
            .new(label: fixture)
            .label(lang: 'womble')
          ).must_equal('WM')
        end

        it 'should pick out the label with the default language if not otherwise specified' do
          _(
            SapiClient::SapiResource
            .new(label: fixture)
            .label
          ).must_equal('EN')
        end
      end

      describe 'automatic methods' do
        let(:fixture) do
          SapiClient::SapiResource.new(name: 'Tobermory', home: { '@id' => 'http://wimbledon.org/common' })
        end

        it 'should respond to object properties as though they were messages' do
          _(fixture.name).must_equal 'Tobermory'
          _(fixture.home.uri).must_equal 'http://wimbledon.org/common'
        end

        it 'should raise when an unknown message is presented' do
          _(-> { fixture.foo }).must_raise(NoMethodError)
        end

        it 'should allow snake_case method names to be used in place of camelCase' do
          fixture = SapiClient::SapiResource.new(prefLabel: 'I am Womble!')
          _(fixture.pref_label).must_equal('I am Womble!')
        end
      end

      describe 'assignment' do
        it 'should directly assign a property of the object' do
          r = SapiClient::SapiResource.new(name: 'Tobermory', home: { '@id' => 'http://wimbledon.org/common' })
          _(r.name).must_equal 'Tobermory'
          r['name'] = 'Uncle Bulgaria'
          _(r.name).must_equal 'Uncle Bulgaria'
        end

        it 'should assign a value at the end of a path' do
          r = SapiClient::SapiResource.new(womble: { name: 'Tobermory' })
          _(r.womble.name).must_equal 'Tobermory'
          r['womble.name'] = 'Uncle Bulgaria'
          _(r.womble.name).must_equal 'Uncle Bulgaria'
        end
      end

      describe '#resolvable?' do
        it 'should be resolvable if a resource has an @id and no other properties' do
          r = SapiClient::SapiResource.new('@id': 'http://wimbledon.common/1234')
          assert r.resolvable?
        end

        it 'should be not resolvable if a resource has no @id' do
          r = SapiClient::SapiResource.new(name: 'wimbledon common')
          refute r.resolvable?
        end

        it 'should be not resolvable if a resource has an @id and other properties' do
          r = SapiClient::SapiResource.new(name: 'wimbledon common', '@id': 'http://wimbledon.common/1234')
          refute r.resolvable?
        end
      end
    end
  end
end
