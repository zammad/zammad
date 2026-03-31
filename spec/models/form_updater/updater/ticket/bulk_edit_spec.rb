# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormUpdater::Updater::Ticket::BulkEdit) do
  subject(:resolved_result) do
    described_class.new(
      context:         context,
      relation_fields: [],
      meta:            meta,
      data:            data,
      id:              nil
    )
  end

  let(:user)    { create(:agent) }
  let(:context) { { current_user: user } }
  let(:meta)    { { initial: true, form_id: SecureRandom.uuid } }
  let(:data)    { {} }

  describe '#authorized?' do
    it 'is authorized for agents' do
      expect(resolved_result.authorized?).to be true
    end

    context 'with customer user' do
      let(:user) { create(:customer) }

      it 'is not authorized for customers' do
        expect(resolved_result.authorized?).to be false
      end
    end

    context 'with admin-only user' do
      let(:user) { create(:user, roles: [Role.find_by(name: 'Admin')]) }

      it 'is not authorized' do
        expect(resolved_result.authorized?).to be false
      end
    end
  end
end
