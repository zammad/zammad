# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::TicketSharedDraftZoomControllerPolicy do
  subject { described_class.new(user, record) }

  let(:record_class) { TicketSharedDraftZoomController }
  let(:ticket)       { create(:ticket) }
  let(:user)         { create(:agent) }
  let(:params)       { { ticket_id: ticket.id, form_id: SecureRandom.uuid } }
  let(:record)       { record_class.new.tap { it.params = params } }

  context 'when has access to ticket' do
    before do
      user.user_groups.create! group: ticket.group, access: :full
    end

    it { is_expected.to permit_actions(:show, :create, :update, :destroy, :import_attachments) }

    context 'when user is customer of the ticket' do
      let(:user) { ticket.customer }

      it { is_expected.to forbid_actions(:show, :create, :update, :destroy, :import_attachments) }
    end

    context 'when form_id points to another users cache' do
      let(:other_user) { create(:agent) }

      before do
        UploadCache.new(params[:form_id]).add(
          filename:      'intruder.txt',
          data:          'Intruder content',
          preferences:   { 'Content-Type' => 'text/plain' },
          created_by_id: other_user.id,
        )
      end

      it { is_expected.to forbid_action(:import_attachments) }
    end
  end

  context 'when has no access to ticket' do
    it { is_expected.to forbid_actions(:show, :create, :update, :destroy, :import_attachments) }
  end

  context 'when user has no access to ticket' do
    it { is_expected.to forbid_all_actions }
  end
end
