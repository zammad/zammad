# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    context 'when has access through roles' do
      let(:role) do
        role = create(:role, :agent)
        role.group_names_access_map = {
          Group.first.name => %w[full],
        }
        role
      end

      let(:user) { create(:agent, role_ids: [role.id]) }

      it { is_expected.to permit_action(action_name) }
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

    let(:record) do
      rec             = record_class.new
      rec.action_name = action_name
      rec.params      = ActionController::Parameters.new(form_id: SecureRandom.uuid)
      rec
    end

    include_examples 'basic checks'

    context 'when form_id points to another users cache' do
      let(:form_id)     { SecureRandom.uuid }
      let(:other_user)  { create(:agent) }

      let(:user) do
        user = create(:agent)
        user.user_groups.create! group: create(:group), access: :full
        user
      end

      let(:record) do
        rec             = record_class.new
        rec.action_name = action_name
        rec.params      = ActionController::Parameters.new(form_id: form_id)
        rec
      end

      before do
        UploadCache.new(form_id).add(
          filename:      'intruder.txt',
          data:          'Intruder content',
          preferences:   { 'Content-Type' => 'text/plain' },
          created_by_id: other_user.id,
        )
      end

      it { is_expected.to forbid_action(action_name) }
    end
  end
end
