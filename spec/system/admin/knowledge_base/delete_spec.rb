# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Admin Panel > Knowledge Base > Delete', type: :system do
  include_context 'basic Knowledge Base'

  before do
    knowledge_base
    visit '/#manage/knowledge_base'
    find('a', text: 'Delete').click
  end

  it 'deletes the knowledge base' do
    find('input[name="title"]').fill_in with: knowledge_base.translations.first.title

    click_on 'Delete Knowledge Base'

    expect(KnowledgeBase.count).to be_zero
  end
end
