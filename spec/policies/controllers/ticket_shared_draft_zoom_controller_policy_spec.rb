# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::TicketSharedDraftZoomControllerPolicy do
  subject { described_class.new(user, record) }

  let(:record_class) { TicketSharedDraftZoomController }
  let(:ticket)       { create(:ticket) }
  let(:user)         { create(:agent) }

  let(:record) do
    rec             = record_class.new
    rec.action_name = action_name
    rec.params      = params

    rec
  end

  shared_examples 'basic checks' do
    let(:params) { { ticket_id: ticket.id } }

    context 'when has access to ticket' do
      before do
        user.user_groups.create! group: ticket.group, access: :full
      end

      it { is_expected.to permit_action(action_name) }
    end

    context 'when has no access to ticket' do
      it { is_expected.to forbid_action(action_name) }
    end
  end

  describe '#show?' do
    let(:action_name) { :show }

    include_examples 'basic checks'
  end

  describe '#create?' do
    let(:action_name) { :create }

    include_examples 'basic checks'
  end

  describe '#update?' do
    let(:action_name) { :update }

    include_examples 'basic checks'
  end

  describe '#destroy?' do
    let(:action_name) { :destroy }

    include_examples 'basic checks'
  end

  describe '#import_attachments?' do
    let(:action_name) { :import_attachments }

    include_examples 'basic checks'
  end
end
