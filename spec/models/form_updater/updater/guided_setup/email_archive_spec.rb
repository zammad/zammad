# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormUpdater::Updater::GuidedSetup::EmailArchive) do
  subject(:resolved_result) do
    described_class.new(
      context:         context,
      relation_fields: relation_fields,
      meta:            meta,
      data:            data,
    )
  end

  let(:user)            { create(:agent) }
  let(:context)         { { current_user: user } }
  let(:meta)            { { initial: true, form_id: SecureRandom.uuid } }
  let(:data)            { {} }
  let(:relation_fields) { [] }

  describe '#resolve' do
    it 'returns default and available states' do
      expect(resolved_result.resolve[:fields]).to include(
        'archive_state_id' => include(
          initialValue: Ticket::State.find_by(name: 'closed').id,
          options:      contain_exactly(
            include(value: Ticket::State.find_by(name: 'closed').id, label: 'closed'),
            include(value: Ticket::State.find_by(name: 'open').id, label: 'open'),
            include(value: Ticket::State.find_by(name: 'new').id, label: 'new')
          )
        )
      )
    end
  end
end
