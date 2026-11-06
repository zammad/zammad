# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::Model::Update, sequencer: :unit do
  let(:instance) { User.find(create(:user, firstname: 'Hans', lastname: 'Mustermann').id) }
  let(:mapped)   { { firstname: 'Hans', lastname: 'Mustermann', created_by_id: 1, created_at: 1.day.ago } }

  before do
    allow(instance).to receive(:with_lock).and_call_original
  end

  context 'when the mapped attributes do not change the instance' do
    it 'provides :unchanged' do
      expect(process(instance: instance, mapped: mapped)).to include(action: :unchanged)
    end

    it 'does not lock the instance' do
      process(instance: instance, mapped: mapped)
      expect(instance).not_to have_received(:with_lock)
    end

    it 'does not assign the creation attributes' do
      process(instance: instance, mapped: mapped)
      expect(instance.changes_to_save).to be_empty
    end
  end

  context 'when the mapped attributes change the instance' do
    let(:mapped) { super().merge(lastname: 'Musterfrau') }

    it 'provides :updated' do
      expect(process(instance: instance, mapped: mapped)).to include(action: :updated)
    end

    it 'locks the instance' do
      process(instance: instance, mapped: mapped)
      expect(instance).to have_received(:with_lock)
    end

    it 'assigns the mapped attributes without saving them' do
      process(instance: instance, mapped: mapped)
      expect(instance.changes_to_save).to eq('lastname' => %w[Mustermann Musterfrau])
    end
  end

  context 'when the record was changed in the meantime' do
    let(:mapped) { super().merge(lastname: 'Musterfrau') }

    before do
      User.find(instance.id).update!(lastname: 'Musterfrau')
    end

    it 'provides :unchanged after locking reloaded the instance' do
      expect(process(instance: instance, mapped: mapped)).to include(action: :unchanged)
    end
  end

  context 'when an action was provided already' do
    it 'skips the update' do
      process(instance: instance, mapped: mapped.merge(lastname: 'Musterfrau'), action: :skipped)
      expect(instance.changes_to_save).to be_empty
    end
  end
end
