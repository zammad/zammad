# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormUpdater::Updater::Ticket::TimeAccounting) do
  subject(:resolved_result) do
    described_class.new(
      context:         context,
      relation_fields: [],
      meta:            meta,
      data:            data,
      id:              nil
    )
  end

  let(:user)          { create(:agent) }
  let(:context)       { { current_user: user } }
  let(:meta)          { { initial: true, form_id: SecureRandom.uuid } }
  let(:data)          { {} }

  let!(:accounted_time_types) { create_list(:ticket_time_accounting_type, 2) }

  let(:expected_result) do
    {
      options: [
        { label: accounted_time_types.first.name, value: accounted_time_types.first.id },
        { label: accounted_time_types.second.name, value: accounted_time_types.second.id },
      ]
    }
  end

  describe '#authorized?' do
    it 'is authorized for agents' do
      expect(resolved_result.authorized?).to be true
    end

    context 'with admin-only user' do
      let(:user) { create(:user, roles: [Role.find_by(name: 'Admin')]) }

      it 'is not authorized' do
        expect(resolved_result.authorized?).to be false
      end
    end
  end

  context 'when resolving' do
    it 'provides accounting types with value + label' do
      expect(resolved_result.resolve[:fields]).to include(
        'accounted_time_type_id' => include(expected_result),
      )
    end
  end
end
