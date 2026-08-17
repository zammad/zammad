# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Controllers::UploadCachesControllerPolicy do
  subject { described_class.new(user, record) }

  let(:record_class) { UploadCachesController }
  let(:form_id)      { SecureRandom.uuid }
  let(:owner)        { create(:user) }

  let(:record) do
    rec = record_class.new
    rec.params = { id: form_id }
    rec
  end

  def self.add_attachment(cache_id, created_by:, name: 'test.txt')
    before do
      resolved_cache_id = cache_id.is_a?(Symbol) ? send(cache_id) : cache_id
      resolved_user     = created_by.is_a?(Symbol) ? send(created_by) : created_by
      UploadCache.new(resolved_cache_id).add(
        filename:      name,
        data:          'test content',
        preferences:   { 'Content-Type' => 'text/plain' },
        created_by_id: resolved_user.id,
      )
    end
  end

  describe '#update?' do
    context 'with populated cache (owned)' do
      add_attachment :form_id, created_by: :owner

      context 'with owner' do
        let(:user) { owner }

        it { is_expected.to permit_action :update }
      end

      context 'with different user' do
        let(:user) { create(:user) }

        it { is_expected.to forbid_action :update }
      end
    end

    context 'with empty cache' do
      let(:user) { create(:user) }

      it { is_expected.to permit_action :update }
    end

    context 'with mixed-owner cache' do
      let(:other_user) { create(:user) }

      add_attachment :form_id, name: 'owner.txt', created_by: :owner
      add_attachment :form_id, name: 'other.txt', created_by: :other_user

      context 'when partial owner' do
        let(:user) { owner }

        it { is_expected.to forbid_action :update }
      end
    end
  end

  describe '#destroy?' do
    context 'with populated cache (owned)' do
      add_attachment :form_id, created_by: :owner

      context 'with owner' do
        let(:user) { owner }

        it { is_expected.to permit_action :destroy }
      end

      context 'with different user' do
        let(:user) { create(:user) }

        it { is_expected.to forbid_action :destroy }
      end
    end

    context 'with empty cache' do
      let(:user) { create(:user) }

      it { is_expected.to permit_action :destroy }
    end

    context 'with mixed-owner cache' do
      let(:other_user) { create(:user) }

      add_attachment :form_id, name: 'owner.txt', created_by: :owner
      add_attachment :form_id, name: 'other.txt', created_by: :other_user

      context 'when partial owner' do
        let(:user) { owner }

        it { is_expected.to forbid_action :destroy }
      end

      context 'when user owns no attachments' do
        let(:user) { create(:user) }

        it { is_expected.to forbid_action :destroy }
      end
    end
  end

  describe '#remove_item?' do
    let(:store_id) { UploadCache.new(form_id).attachments(created_by_id: nil).first&.id }

    let(:record) do
      rec = record_class.new
      rec.params = { id: form_id, store_id: store_id }
      rec
    end

    context 'with own attachment' do
      add_attachment :form_id, created_by: :owner
      let(:user) { owner }

      it { is_expected.to permit_action :remove_item }
    end

    context 'with attachment owned by another user' do
      add_attachment :form_id, created_by: :owner
      let(:user) { create(:user) }

      it { is_expected.to forbid_action :remove_item }
    end

    context 'with mixed-owner cache' do
      let(:other_user) { create(:user) }

      add_attachment :form_id, name: 'owner.txt', created_by: :owner
      add_attachment :form_id, name: 'other.txt', created_by: :other_user

      context 'when partial owner removes their own item' do
        let(:user)     { owner }
        let(:store_id) { UploadCache.new(form_id).attachments(created_by_id: owner.id).first&.id }

        it { is_expected.to forbid_action :remove_item }
      end
    end
  end
end
