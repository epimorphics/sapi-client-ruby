# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class HierarchyTest < Minitest::Test
    describe 'Hierarchy' do
      # test hierarchy fixture:
      #
      #         root1        root2
      #         /   \          |
      #        a     b         c
      #        |
      #        a1
      let(:root1) { { prefLabel: 'root1', topConceptOf: 'myscheme', '@id': 'http://example.com/root1' } }
      let(:root2) { { prefLabel: 'root2', topConceptOf: 'myscheme', '@id': 'http://example.com/root2' } }
      let(:a) { { prefLabel: 'a', broader: [{ '@id': 'http://example.com/root1' }], '@id': 'http://example.com/a' } }
      let(:a1) { { prefLabel: 'a1', broader: [{ '@id': 'http://example.com/a' }], '@id': 'http://example.com/a1' } }
      let(:b) { { prefLabel: 'b', broader: [{ '@id': 'http://example.com/root1' }], '@id': 'http://example.com/b' } }
      let(:c) { { prefLabel: 'c', broader: [{ '@id': 'http://example.com/root2' }], '@id': 'http://example.com/c' } }

      let(:resources) do
        [root1, a, b, c, root2, a1].map { |resource| SapiClient::SapiResource.new(resource) }
      end

      describe '#initialize' do
        it 'should create a resource hierarchy' do
          fixture = Hierarchy.new(resources, :skos)

          _(fixture.resources.length).must_equal(resources.length)
          resources.each do |resource|
            assert _(fixture.resources.filter { |r| r.prefLabel == resource.prefLabel })
          end
        end

        it 'should recognise the built-in scheme' do
          fixture = Hierarchy.new(resources, :skos)
          _(fixture.scheme.root_property).must_equal 'topConceptOf'
          _(fixture.scheme.parent_property).must_equal 'broader'
        end

        it 'should permit a custom scheme' do
          my_scheme = OpenStruct.new(
            root_property: 'rp',
            parent_property: 'pp'
          )
          fixture = Hierarchy.new(resources, my_scheme)

          _(fixture.scheme.root_property).must_equal 'rp'
        end
      end

      describe '#roots' do
        it 'should find the roots of the hierarchy' do
          fixture = Hierarchy.new(resources, :skos)
          roots = fixture.roots

          _(roots.length).must_equal 2
          _(roots.map(&:prefLabel)).must_include('root1')
          _(roots.map(&:prefLabel)).must_include('root2')
        end
      end

      describe '#traverse' do
        it 'should traverse the hierarchy, in breadth-first order' do
          fixture = Hierarchy.new(resources, :skos)
          acc = []
          fixture.traverse(:breadth_first) do |resource|
            acc.push(resource.prefLabel)
          end

          _(acc).must_equal(%w[root1 root2 a b c a1])
        end

        it 'should traverse the hierarchy, in depth-first order' do
          fixture = Hierarchy.new(resources, :skos)
          acc = []
          fixture.traverse(:depth_first) do |resource|
            acc.push(resource.prefLabel)
          end

          _(acc).must_equal(%w[root1 a a1 b root2 c])
        end
      end
    end
  end
end
