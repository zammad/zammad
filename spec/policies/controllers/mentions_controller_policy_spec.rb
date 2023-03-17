# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::MentionsControllerPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:user)         { create(:agent_and_customer) }
  let(:ticket)       { create(:ticket) }
  let(:record_class) { MentionsController }

  let(:record) do
    rec             = record_class.new
    rec.params      = params

    rec
  end

  context 'with ticket' do
    let(:params) do
      {
        mentionable_type: 'Ticket',
        mentionable_id:   ticket.id
      }
    end

    context 'with agent access' do
      before { user.user_groups.create! group: ticket.group, access: 'full' }

      it { is_expected.to permit_actions %i[index create] }
    end

    context 'with agent read access' do
      before { user.user_groups.create! group: ticket.group, access: 'read' }

      it { is_expected.to permit_actions %i[index create] }
    end

    context 'with customer access' do
      before { ticket.update! customer: user }

      it { is_expected.to forbid_actions %i[index create] }
    end

    context 'with no access' do
      it { is_expected.to forbid_actions %i[index create] }
    end
  end

  context 'with non-ticket' do
    let(:params) do
      {
        mentionable_type: 'NonTicket',
        mentionable_id:   123
      }
    end

    it { is_expected.to forbid_actions(%i[index create]) }

    it { expect { policy.index? }.to change(policy, :custom_exception).to(Exceptions::UnprocessableEntity) }
    it { expect { policy.create? }.to change(policy, :custom_exception).to(Exceptions::UnprocessableEntity) }
  end

  context 'with mention' do
    let(:params)  { { id: mention.id } }

    let(:mention) do
      mention = build(:mention, mentionable: ticket, user: mention_user)
      mention.save(validate: false)
      mention
    end

    context 'when self mention exists' do
      let(:mention_user) { user }

      context 'when user has agent access to object' do
        before { user.user_groups.create! group: ticket.group, access: 'full' }

        it { is_expected.to permit_action :destroy }
      end

      context 'when user has no agent access to object' do
        it { is_expected.to permit_action :destroy }
      end
    end

    context 'when another user\'s mention exists' do
      let(:mention_user) { create(:user) }

      it { is_expected.to forbid_action :destroy }
    end

    context 'when mention does not exist' do
      let(:params) { { id: 0 } }

      it { is_expected.to forbid_action :destroy }
    end
  end
end
