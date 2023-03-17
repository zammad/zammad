# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe KnowledgeBase::AnswerPolicy::Scope, current_user_id: 1 do
  subject(:scope) { described_class.new(user, original_collection) }

  let(:original_collection) { KnowledgeBase::Answer }

  before do # populate DB
    create_list(:'knowledge_base/answer', 2, published_at: Time.zone.yesterday)
    create_list(:'knowledge_base/answer', 2, published_at: Time.zone.yesterday, archived_at: Time.zone.now)
  end

  describe '#resolve' do
    let(:roles) { user.roles }
    let(:permission) { Permission.find_by(name: 'knowledge_base.editor') }

    context 'without user' do
      let(:user) { nil }

      it 'removes unpublished and archived answers' do
        expect(scope.resolve)
          .to match_array(original_collection.where(<<~QUERY, now: Time.zone.now))
            published_at < :now AND (archived_at IS NULL OR archived_at > :now)
          QUERY
      end
    end

    context 'without "knowledge_base.editor" permissions' do
      let(:user) { create(:admin) }

      before { roles.each { |r| r.permissions.delete(permission) } }

      it 'removes unpublished and archived answers' do
        expect(scope.resolve)
          .to match_array(original_collection.where(<<~QUERY, now: Time.zone.now))
            published_at < :now AND (archived_at IS NULL OR archived_at > :now)
          QUERY
      end
    end

    context 'with "knowledge_base.editor" permissions' do
      let(:user) { create(:user) }

      before { roles.first.permissions << permission }

      it 'returns the given collection (unfiltered)' do
        expect(scope.resolve).to eq(original_collection)
      end
    end
  end
end
