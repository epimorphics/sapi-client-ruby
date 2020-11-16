# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

module SapiClient
  class HierarchyResourceTest < Minitest::Test
    describe 'HierarchyResource' do
      describe '#initialize' do
        it 'should create a hierarchy resource as a sub-class of resource' do
          fixture = HierarchyResource.new(prefLabel: 'womble')

          _(fixture.prefLabel).must_equal('womble')
        end

        it 'should start with no parent and no children' do
          fixture = HierarchyResource.new(prefLabel: 'womble')

          _(fixture.parent).must_be_nil
          _(fixture.children).must_equal([])
        end
      end

      describe '#parent=' do
        it 'should set the parent' do
          fixture1 = HierarchyResource.new(prefLabel: 'wombles')
          fixture2 = HierarchyResource.new(prefLabel: 'womble')

          fixture2.parent = fixture1

          _(fixture1.parent).must_be_nil
          _(fixture2.parent.prefLabel).must_equal('wombles')
          _(fixture2.children).must_equal([])
          _(fixture1.children.length).must_equal(1)
          _(fixture1.children.first.prefLabel).must_equal('womble')
        end
      end

      describe '#add_child' do
        it 'should add a first child' do
          fixture1 = HierarchyResource.new(prefLabel: 'wombles')
          fixture2 = HierarchyResource.new(prefLabel: 'bulgaria')

          fixture1.add_child(fixture2)

          _(fixture1.parent).must_be_nil
          _(fixture2.parent).must_equal(fixture1)
          _(fixture2.children).must_equal([])
          _(fixture1.children).must_equal([fixture2])
        end

        it 'should add a second child' do
          fixture1 = HierarchyResource.new(prefLabel: 'wombles')
          fixture2 = HierarchyResource.new(prefLabel: 'bulgaria')
          fixture3 = HierarchyResource.new(prefLabel: 'tobermory')

          fixture1.add_child(fixture2)
          fixture1.add_child(fixture3)

          _(fixture1.parent).must_be_nil
          _(fixture2.parent).must_equal(fixture1)
          _(fixture3.parent).must_equal(fixture1)
          _(fixture2.children).must_equal([])
          _(fixture3.children).must_equal([])
          _(fixture1.children).must_equal([fixture2, fixture3])
        end
      end

      describe '#each_child' do
        it 'should iterate over each child' do
          fixture1 = HierarchyResource.new(prefLabel: 'wombles')
          fixture2 = HierarchyResource.new(prefLabel: 'bulgaria')
          fixture3 = HierarchyResource.new(prefLabel: 'tobermory')

          fixture1.add_child(fixture2)
          fixture1.add_child(fixture3)

          collector = []

          fixture1.each_child do |child|
            collector << child.prefLabel
          end

          _(collector).must_equal(%w[bulgaria tobermory])
        end
      end
    end
  end
end
