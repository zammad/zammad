# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe UploadCachePolicy do
  subject { described_class.new(effective_user, record) }

  let(:user)   { create(:user) }
  let(:record) do
    cache = UploadCache.new(123)

    cache.add(
      filename:      'hello_world.txt',
      data:          'Hello, World!',
      preferences:   { 'Content-Type' => 'text/plain' },
      created_by_id: user.id
    )

    cache
  end

  context 'with empty cache' do
    let(:record)           { UploadCache.new(123) }
    let(:effective_user)   { create(:user) }

    it { is_expected.to permit_actions :add, :any, :show, :destroy, :remove_item }
  end

  context 'with different user' do
    let(:effective_user) { create(:user) }

    it { is_expected.to forbid_actions :add, :any, :show, :destroy, :remove_item }
  end

  context 'with given user' do
    let(:effective_user) { user }

    it { is_expected.to permit_actions :add, :any, :show, :destroy, :remove_item }
  end

  context 'with mixed-owner cache' do
    let(:other_user) { create(:user) }
    let(:record) do
      cache = UploadCache.new(SecureRandom.uuid)

      cache.add(
        filename:      'other_user.txt',
        data:          'Data from other user',
        preferences:   { 'Content-Type' => 'text/plain' },
        created_by_id: other_user.id
      )
      cache.add(
        filename:      'current_user.txt',
        data:          'Data from current user',
        preferences:   { 'Content-Type' => 'text/plain' },
        created_by_id: user.id
      )

      cache
    end

    context 'when user owns some but not all attachments' do
      let(:effective_user) { user }

      it { is_expected.to forbid_actions :add, :any, :show, :destroy, :remove_item }
    end

    context 'when user owns all attachments' do
      let(:effective_user) { other_user }
      let(:record) do
        cache = UploadCache.new(SecureRandom.uuid)

        cache.add(
          filename:      'other_user.txt',
          data:          'Data from other user',
          preferences:   { 'Content-Type' => 'text/plain' },
          created_by_id: other_user.id
        )

        cache
      end

      it { is_expected.to permit_actions :add, :any, :show, :destroy, :remove_item }
    end
  end
end
