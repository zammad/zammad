# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AvatarCreateJob, type: :job do
  subject(:perform) { described_class.perform_now user }

  let(:user) { create(:user) }
  let(:hash) { SecureRandom.hex(16) }

  context 'with avatar auto detection' do
    before do
      allow(Avatar).to receive(:auto_detection).and_return(avatar)
      user
      travel 1.minute
    end

    context 'when succesful' do
      let(:avatar) { create(:avatar, o_id: user.id, store_hash: hash) }

      it 'changes user image' do
        expect { perform }
          .to change { user.reload.image }
          .from(nil)
      end

      it 'touches user' do
        expect { perform }
          .to change { user.reload.updated_at }
      end
    end

    context 'when unsuccesful' do
      let(:avatar) { nil }

      it 'does not change user image' do
        expect { perform }
          .not_to change { user.reload.image }
          .from(nil)
      end

      it 'does not touch user' do
        expect { perform }
          .not_to change { user.reload.updated_at }
      end
    end
  end

  it 'retries on exception' do
    allow(Avatar).to receive(:auto_detection).and_raise(RuntimeError)

    perform
    expect(described_class).to have_been_enqueued
  end
end
