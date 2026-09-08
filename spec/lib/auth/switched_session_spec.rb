# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth::SwitchedSession do
  describe '.revoked?' do
    subject(:revoked) { described_class.revoked?(switched_from_user_id) }

    context 'without a switched user' do
      let(:switched_from_user_id) { nil }

      it { is_expected.to be(false) }
    end

    # SessionsController#switch_back_to_user sets the key to nil instead of removing it, so an
    #   empty value has to count as 'not switched' rather than as a user that cannot be found.
    context 'with an empty switched user' do
      let(:switched_from_user_id) { '' }

      it { is_expected.to be(false) }
    end

    context 'when an admin switched to another user' do
      let(:admin)                 { create(:admin) }
      let(:switched_from_user_id) { admin.id }

      it { is_expected.to be(false) }

      # Bypasses the callback that drops the admin's sessions (see User::TerminatesSessions), so
      #   that this covers the prerequisite itself.
      context 'when the admin is deactivated' do
        before { admin.update_columns(active: false) }

        it { is_expected.to be(true) }
      end

      context 'when the admin is deleted' do
        before { admin.destroy! }

        it { is_expected.to be(true) }
      end
    end
  end
end
