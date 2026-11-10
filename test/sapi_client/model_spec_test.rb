# frozen_string_literal: true

require 'test_helper'
require 'sapi_client'

# Dummy wrapper classes used to exercise the selection of the most-specific
# Ruby class when a resource carries several `@type` declarations. They are
# deliberately given unique names so they do not clash with the domain model
# classes that the API gems will eventually define under their own modules
# (for example `Fsa::Rp::Api::Authorisation`).
class ModelSpecAuthorisation < SapiClient::SapiResource; end
class ModelSpecGmoAuthorisation < ModelSpecAuthorisation; end

module SapiClient
  # The aim of these tests is to record the desired behaviour and the current
  # boundaries. Tests for behaviour that has not been implemented yet are marked
  # `skip` so the suite stays green.
  class ModelSpecTest < Minitest::Test
    describe 'model spec resource typing' do
      let(:base_url) { 'https://fsa-dev-rp.epimorphics.net' }
      let(:auth_uri) { 'http://data.food.gov.uk/regulated-products/def/core/Authorisation' }
      let(:gmo_uri) { 'http://data.food.gov.uk/regulated-products/def/gmo/GmoAuthorisation' }
      let(:rp_app) { SapiClient::Application.new(base_url, REGULATED_PRODUCTS_SPEC_FILE) }
      let(:rp_model) { rp_app.instance_variable_get(:@parsed_model_spec) }
      let(:rp_model_names) { rp_app.instance_variable_get(:@model_class_names) }
      let(:rp_model_yaml) { YAML.load_file(File.join(REGULATED_PRODUCTS_SPEC_DIR, 'model.yaml')) }

      describe 'model spec parsing' do
        it 'should index each class under its full URI, QName and local name' do
          [auth_uri, 'core:Authorisation', 'Authorisation'].each do |key|
            assert rp_model.key?(key), "expected parsed model spec to contain #{key}"
          end
        end

        it 'should record the Ruby class name for a class QName, full URI and local name' do
          _(rp_model_names['gmo:GmoAuthorisation']).must_equal 'GmoAuthorisation'
          _(rp_model_names[gmo_uri]).must_equal 'GmoAuthorisation'
          _(rp_model_names['GmoAuthorisation']).must_equal 'GmoAuthorisation'
        end

        it 'should resolve a property with a single range to its Ruby type' do
          _(rp_model[gmo_uri]['phase']).must_equal 'Phase'
        end

        it 'should resolve an object property range to the declared Ruby class name' do
          _(rp_model[auth_uri]['holder']).must_equal '( Agent | nil )'
        end

        it 'should represent a property with several ranges as a union of types' do
          _(rp_model[auth_uri]['ordinal']).must_equal '( String | Integer | BigDecimal | nil )'
        end

        it 'should collapse equivalent ranges to a single type in a union' do
          _(rp_model[gmo_uri]['transitionEnd']).must_equal '( String | Date | DateTime | nil )'
        end
      end

      describe 'selecting a wrapper class from several @type declarations' do
        let(:model_class_names) do
          {
            auth_uri => 'ModelSpecAuthorisation',
            gmo_uri => 'ModelSpecGmoAuthorisation'
          }
        end

        it 'should prefer the most-specific class when supertype and subtype are both present' do
          original = SapiClient::SapiResource.model_class_names
          SapiClient::SapiResource.model_class_names = model_class_names
          begin
            _(
              ResourceWrapper.find_wrapper_type([auth_uri, gmo_uri])
            ).must_equal ModelSpecGmoAuthorisation
          ensure
            SapiClient::SapiResource.model_class_names = original
          end
        end

        it 'should select the most-specific class regardless of declaration order' do
          original = SapiClient::SapiResource.model_class_names
          SapiClient::SapiResource.model_class_names = model_class_names
          begin
            _(
              ResourceWrapper.find_wrapper_type([gmo_uri, auth_uri])
            ).must_equal ModelSpecGmoAuthorisation
          ensure
            SapiClient::SapiResource.model_class_names = original
          end
        end

        it 'should wrap a raw resource using the most-specific declared type' do
          original = SapiClient::SapiResource.model_class_names
          SapiClient::SapiResource.model_class_names = model_class_names
          begin
            resource = { 'type' => [{ '@id' => auth_uri }, { '@id' => gmo_uri }] }
            _(ResourceWrapper.wrap_resource(resource)).must_be_kind_of ModelSpecGmoAuthorisation
          ensure
            SapiClient::SapiResource.model_class_names = original
          end
        end

        it 'should fall back to the superclass when only the superclass type is declared' do
          original = SapiClient::SapiResource.model_class_names
          SapiClient::SapiResource.model_class_names = model_class_names
          begin
            _(
              ResourceWrapper.find_wrapper_type([auth_uri])
            ).must_equal ModelSpecAuthorisation
          ensure
            SapiClient::SapiResource.model_class_names = original
          end
        end

        it 'should infer a more-specific subclass when only the superclass type is declared' do
          skip 'the client does not yet infer subclasses from a polymorphic superclass'
          # Once subclasses are inferrable, the single superclass type should still
          # resolve to the most-specific implementing class:
          #
          # _(ResourceWrapper.find_wrapper_type([auth_uri])).must_equal ModelSpecGmoAuthorisation
        end
      end

      describe 'name clashes between model specs' do
        it 'should keep type signatures from different model specs distinct' do
          skip 'parsed model specs are currently stored in a single global registry'
          # Each parsed model.yaml should be isolated in its own Ruby module, much
          # like the API gems already namespace their spec under Fsa::Rp::Api and
          # Fsa::Cbd::Api. When un-skipped, this should verify that an RP model
          # class and a CBD model class with the same local name (for example
          # `Agent`) do not overwrite each other.
        end

        it 'should namespace declared class names under the owning API module' do
          skip 'declared class names are currently resolved as top-level constants'
          # `ResourceWrapper.wrapper_class_constant` uses `Kernel.const_get`, so a
          # class declared as `Authorisation` in the RP model should be looked up
          # as `Fsa::Rp::Api::Authorisation` rather than `::Authorisation`.
        end
      end

      describe 'polymorphism declared on a superclass' do
        it 'should declare Authorisation as polymorphic in the source spec' do
          authorisation = rp_model_yaml['classes'].find { |cls| cls['class'] == 'core:Authorisation' }
          _(authorisation['polymorphic']).must_equal true
        end

        it 'should declare GmoAuthorisation as a subclass of Authorisation' do
          gmo = rp_model_yaml['classes'].find { |cls| cls['class'] == 'gmo:GmoAuthorisation' }
          _(gmo['subClassOf']).must_equal 'core:Authorisation'
        end

        it 'should declare the subclass-only property on the subclass' do
          gmo = rp_model_yaml['classes'].find { |cls| cls['class'] == 'gmo:GmoAuthorisation' }
          property_names = gmo['properties'].map do |prop|
            prop.is_a?(Hash) ? prop['name'] : prop.sub(/^[^:]*:/, '')
          end

          _(property_names).must_include 'environmentalMonitoring'
        end

        it 'should expose subclass-only properties on a subclass-typed resource' do
          original = SapiClient::SapiResource.parsed_model_spec
          SapiClient::SapiResource.parsed_model_spec = rp_model
          begin
            resource = SapiClient::SapiResource.new(
              '@id' => 'http://data.food.gov.uk/regulated-products/id/gmo/authorisation/gmoauth-49',
              'type' => { '@id' => gmo_uri }
            )

            assert resource.respond_to?(:environmental_monitoring)
            assert_nil resource.environmental_monitoring
          ensure
            SapiClient::SapiResource.parsed_model_spec = original
          end
        end

        it 'does not currently expose subclass-only properties on a superclass-typed resource' do
          original = SapiClient::SapiResource.parsed_model_spec
          SapiClient::SapiResource.parsed_model_spec = rp_model
          begin
            resource = SapiClient::SapiResource.new(
              '@id' => 'http://data.food.gov.uk/regulated-products/id/core/authorisation/1',
              'type' => { '@id' => auth_uri }
            )

            refute resource.respond_to?(:environmental_monitoring)
          ensure
            SapiClient::SapiResource.parsed_model_spec = original
          end
        end

        it 'should expose subclass-only properties on a polymorphic superclass' do
          skip 'polymorphism is not yet implemented'
          # When a superclass is marked polymorphic (and the actual subclass can be
          # determined), a resource typed only as the superclass should still expose
          # subclass-specific properties such as `environmental_monitoring`.
        end
      end
    end
  end
end
