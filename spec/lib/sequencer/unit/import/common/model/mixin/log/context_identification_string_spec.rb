# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::Model::Mixin::Log::ContextIdentificationString do

  before do
    stub_const unit_class_namespace, unit_class
  end

  let(:unit_class_namespace) { "#{Sequencer::Unit::PREFIX}SomeIdentifyingUnit" }

  let(:unit_class) do
    Class.new(Sequencer::Unit::Base) do
      include Sequencer::Unit::Import::Common::Model::Mixin::Log::ContextIdentificationString

      provides :context_identification_string

      def process
        state.provide(:context_identification_string, context_identification_string)
      end
    end
  end

  let(:result) do
    result = Sequencer::Unit.process(unit_class_namespace, parameters)
    result[:context_identification_string]
  end

  context 'when no attributes to identify by are given' do

    let(:parameters) { {} }

    it 'returns an empty string' do
      expect(result).to eq ''
    end
  end

  context "when 'model_class' attribute is given" do

    let(:model_class) { ::User }
    let(:parameters) { { model_class: model_class } }

    it 'adds Model class name and lookup_keys' do
      expect(result).to include(model_class.name, *model_class.lookup_keys.map(&:to_s))
    end
  end

  context "when 'resource' attribute is given" do

    let(:parameters) { { resource: resource } }

    context "when 'resource' has identifier methods" do

      let(:resource) { double('Some remote resource', id: SecureRandom.base58, foo: SecureRandom.base58) } # rubocop:disable RSpec/VerifiedDoubles

      it 'adds resource identifiers' do
        expect(result).to include(resource.id)
      end

      it "doesn't include other resource attributes" do
        expect(result).not_to include(resource.foo)
      end
    end

    context "when 'resource' has Hash like accessor" do

      let(:resource) { { id: SecureRandom.base58, foo: SecureRandom.base58 } }

      it 'adds resource identifiers' do
        expect(result).to include(resource[:id])
      end

      it "doesn't include other resource attributes" do
        expect(result).not_to include(resource[:foo])
      end
    end
  end

  context "when 'mapped' attribute is given" do

    let(:mapped) { { id: SecureRandom.base58, foo: SecureRandom.base58 } }
    let(:parameters) { { mapped: mapped } }

    it 'adds mapped identifiers' do
      expect(result).to include(mapped[:id])
    end

    it "doesn't include other mapped attributes" do
      expect(result).not_to include(mapped[:foo])
    end
  end

  context "when 'instance' attribute is given" do

    let(:instance) { build(:user, password: 'foo') }
    let(:parameters) { { instance: instance } }

    it 'adds instance identifiers' do
      expect(result).to include(*instance.class.lookup_keys.map(&:to_s))
    end

    it "doesn't include other instance attributes" do
      expect(result).not_to include(instance.password)
    end
  end
end
