# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::AI::Analytics::DownloadsControllerPolicy do
  subject { described_class.new(user, record) }

  let(:record_class) { AI::Analytics::DownloadsController }

  let(:record) do
    rec        = record_class.new
    rec.params = params
    rec
  end

  let(:params) { {} }

  describe '#download?' do
    context 'when user has admin.ai_provider permission' do
      let(:user) { create(:admin) }

      it { is_expected.to permit_action(:download) }
    end

    context 'when user does not have admin.ai_provider permission (agent)' do
      let(:user) { create(:agent) }

      it { is_expected.to forbid_action(:download) }
    end

    context 'when user is customer' do
      let(:user) { create(:customer) }

      it { is_expected.to forbid_action(:download) }
    end

    context 'when permission is inactive' do
      let(:user) { create(:admin) }

      before do
        Permission.find_by(name: 'admin.ai_provider').update!(active: false)
      end

      it { is_expected.to forbid_action(:download) }
    end
  end
end
