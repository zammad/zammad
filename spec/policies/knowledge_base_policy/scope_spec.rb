# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe KnowledgeBasePolicy::Scope do
  subject(:scope) { described_class.new(user, original_collection) }

  let(:original_collection) { KnowledgeBase }

  before do # populate DB
    create_list(:knowledge_base, 2, active: true)
    create_list(:knowledge_base, 2, active: false)
  end

  describe '#resolve' do
    let(:roles) { user.roles }
    let(:permission) { Permission.find_by(name: 'knowledge_base.editor') }

    context 'without user' do
      let(:user) { nil }

      it 'removes only inactive knowledge bases' do
        expect(scope.resolve).to eq(original_collection.where(active: true))
      end
    end

    context 'without "knowledge_base.editor" permissions' do
      let(:user) { create(:admin) }

      before { roles.each { |r| r.permissions.delete(permission) } }

      it 'removes only inactive knowledge bases' do
        expect(scope.resolve).to eq(original_collection.where(active: true))
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
