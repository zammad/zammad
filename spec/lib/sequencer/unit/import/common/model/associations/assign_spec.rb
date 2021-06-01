# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::Model::Associations::Assign, sequencer: :unit do
  let(:parameters) do
    {
      instance:     instance,
      associations: associations,
      action:       action,
      dry_run:      false
    }
  end

  context 'when given an `associations` hash that changes the instance' do
    let(:instance)     { create(:user) }
    let(:action)       { :created }
    let(:associations) do
      alt_org = Organization.where.not(id: instance.organization_id.to_i).pluck(:id).sample
      { organization_id: alt_org }
    end

    it 'assigns (NOT updates) the associations' do
      process(parameters)
      expect(instance.changes).to include(:organization_id)
    end

    it 'changes `:action => :unchanged` to `:action => :updated`' do
      parameters[:action] = :unchanged
      expect(process(parameters)).to include(action: :updated)
    end
  end

  context 'when given a `associations` hash that does NOT change the instance' do
    let(:instance)     { create(:user) }
    let(:associations) { { organization_id: instance.organization_id } }
    let(:action) { :unchanged }

    it 'keeps `:action => :unchanged`' do
      expect(process(parameters)).to include(action: :unchanged)
    end
  end

  context 'when given an empty `associations` hash' do
    let(:instance)     { create(:user) }
    let(:action)       { :created }
    let(:associations) { {} }

    it 'makes no changes' do
      provided = process(parameters)

      expect(provided).to include(action: action)
      expect(instance.changed?).to be(false)
    end
  end

  context 'when given nil for `associations`' do
    let(:instance)     { create(:user) }
    let(:associations) { nil }

    context 'and `action == :skipped`' do
      let(:action) { :skipped }

      it 'makes no changes' do
        allow(Rails.logger).to receive(:error).and_call_original

        provided = process(parameters)

        expect(Rails.logger).not_to have_received(:error)
        expect(provided).to include(action: action)
        expect(instance.changed?).to be(false)
      end
    end

    context 'and `action == :failed`' do
      let(:action) { :failed }

      it 'makes no changes' do
        provided = process(parameters)

        expect(provided).to include(action: action)
        expect(instance.changed?).to be(false)
      end
    end

    context 'and `action == :deactivated`' do
      let(:action) { :deactivated }

      it 'makes no changes' do
        provided = process(parameters)

        expect(provided).to include(action: action)
        expect(instance.changed?).to be(false)
      end
    end

    context 'and any other value of `action`' do
      let(:action) { :created }

      it 'makes no changes and logs an error' do
        allow(Rails.logger).to receive(:error).with(any_args)

        provided = process(parameters)

        expect(provided).to include(action: action)
        expect(instance.changed?).to be(false)
        expect(Rails.logger).to have_received(:error)
      end
    end
  end
end
