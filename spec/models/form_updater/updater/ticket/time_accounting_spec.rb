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
    before { Setting.set('time_accounting_types', true) }

    it 'provides accounting types with value + label' do
      expect(resolved_result.resolve[:fields]).to include(
        'accounted_time_type_id' => include(expected_result),
      )
    end

    it 'shows the field' do
      expect(resolved_result.resolve[:fields]).to include(
        'accounted_time_type_id' => include(show: true),
      )
    end

    context 'when activity types are disabled' do
      before { Setting.set('time_accounting_types', false) }

      it 'hides the field' do
        expect(resolved_result.resolve[:fields]).to include(
          'accounted_time_type_id' => include(show: false),
        )
      end
    end

    context 'without any active type' do
      let!(:accounted_time_types) { create_list(:ticket_time_accounting_type, 2, active: false) }

      it 'hides the field and provides no options' do
        expect(resolved_result.resolve[:fields]).to include(
          'accounted_time_type_id' => include(show: false, options: []),
        )
      end
    end

    context 'with a default activity type' do
      before { Setting.set('time_accounting_type_default', accounted_time_types.first.id) }

      it 'pre-selects the default type' do
        expect(resolved_result.resolve[:fields]).to include(
          'accounted_time_type_id' => include(value: accounted_time_types.first.id),
        )
      end

      context 'when the default type is inactive' do
        before { accounted_time_types.first.update!(active: false) }

        it 'pre-selects nothing' do
          expect(resolved_result.resolve[:fields]).to include(
            'accounted_time_type_id' => include(value: nil),
          )
        end
      end
    end
  end
end
