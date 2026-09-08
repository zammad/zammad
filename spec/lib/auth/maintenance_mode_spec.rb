# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth::MaintenanceMode do
  describe '.blocks?' do
    subject(:blocks) { described_class.blocks?(user, switched_from_user_id: switched_from_user_id) }

    let(:switched_from_user_id) { nil }
    let(:user)                  { create(:customer) }

    context 'without maintenance mode' do
      it { is_expected.to be(false) }
    end

    context 'with maintenance mode' do
      before { Setting.set('maintenance_mode', true) }

      it { is_expected.to be(true) }

      context 'when the user has maintenance permissions' do
        let(:user) { create(:admin) }

        it { is_expected.to be(false) }
      end

      context 'when an admin switched to the user' do
        let(:switched_from_user_id) { create(:admin).id }

        it { is_expected.to be(false) }
      end
    end
  end
end
