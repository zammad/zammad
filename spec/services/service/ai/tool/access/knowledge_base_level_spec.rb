# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Access::KnowledgeBaseLevel, :aggregate_failures do
  let(:editor) { create(:admin) }

  def with_token(permissions, user: editor, &)
    UserInfo.with_token(create(:token, user:, preferences: { permission: permissions }), &)
  end

  describe '.of' do
    let(:reader) { create(:agent) }

    it 'follows the user\'s permissions without a token' do
      expect(described_class.of(editor)).to eq('editor')
      expect(described_class.of(reader)).to eq('reader')
      expect(described_class.of(create(:agent, roles: [create(:role, permission_names: %w[ticket.agent])]))).to eq('published')
    end

    it 'is narrowed by a token to its own permissions' do
      expect(with_token(%w[knowledge_base.editor]) { described_class.of(editor) }).to eq('editor')
      expect(with_token(%w[knowledge_base.reader]) { described_class.of(editor) }).to eq('reader')
      expect(with_token(%w[ticket.agent]) { described_class.of(editor) }).to eq('published')
    end

    it 'is never widened by a token: a permission counts only where the token and the user both hold it' do
      expect(with_token(%w[knowledge_base.editor], user: reader) { described_class.of(reader) }).to eq('published')
    end
  end

  describe '.cap' do
    let(:category)  { create(:knowledge_base_category) }
    let(:published) { create(:knowledge_base_answer, :published, category:) }
    let(:internal)  { create(:knowledge_base_answer, :internal, category:) }
    let(:draft)     { create(:knowledge_base_answer, :draft, category:) }
    let(:archived)  { create(:knowledge_base_answer, :archived, category:) }

    def capped(record, token_permissions = nil)
      result = Pundit.policy(editor, record).show?
      return described_class.cap(record, result, editor) if token_permissions.nil?

      with_token(token_permissions) { described_class.cap(record, result, editor) }
    end

    def readable?(...)
      !!capped(...)
    end

    it 'keeps what the policy allowed without a token, and for an editor\'s token' do
      expect([published, internal, draft, archived].map { |answer| readable?(answer) }).to all(be(true))
      expect([published, internal, draft, archived].map { |answer| readable?(answer, %w[knowledge_base.editor]) }).to all(be(true))
    end

    it 'keeps the internally and publicly published answers for a reader\'s token' do
      expect([published, internal, draft, archived].map { |answer| readable?(answer, %w[knowledge_base.reader]) }).to eq([true, true, false, false])
    end

    it 'keeps the published answers for a token without a knowledge base permission, with the fields the help site shows' do
      expect([published, internal, draft, archived].map { |answer| readable?(answer, %w[ticket.agent]) }).to eq([true, false, false, false])

      scope = capped(published.translations.first, %w[ticket.agent])
      expect(scope.field_authorized?(:title)).to be(true)
      expect(scope.field_authorized?(:edited_at)).to be(false)
    end

    it 'judges a translation by its answer' do
      expect(readable?(draft.translations.first, %w[knowledge_base.reader])).to be(false)
      expect(readable?(internal.translations.first, %w[knowledge_base.reader])).to be(true)
    end

    it 'never widens what the policy refused, and leaves other records alone' do
      expect(described_class.cap(published, false, editor)).to be(false)
      expect(described_class.cap(create(:ticket), true, editor)).to be(true)
    end
  end
end
