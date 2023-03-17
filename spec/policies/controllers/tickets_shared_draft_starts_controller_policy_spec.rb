# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::TicketsSharedDraftStartsControllerPolicy do
  subject { described_class.new(user, record) }

  let(:record_class) { TicketsSharedDraftStartsController }

  let(:record) do
    rec             = record_class.new
    rec.action_name = action_name

    rec
  end

  shared_examples 'basic checks' do
    context 'when has access to tickets' do
      let(:user) do
        user = create(:agent)
        user.user_groups.create! group: create(:group), access: :full
        user
      end

      it { is_expected.to permit_action(action_name) }
    end

    context 'when has no access to tickets' do
      let(:user) { create(:customer) }

      it { is_expected.to forbid_action(action_name) }
    end
  end

  describe '#index?' do
    let(:action_name) { :index }

    include_examples 'basic checks'
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
