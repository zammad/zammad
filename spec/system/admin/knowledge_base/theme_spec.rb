# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# https://github.com/zammad/zammad/issues/266
RSpec.describe 'Admin Panel > Knowledge Base > Theme', type: :system do
  include_context 'basic Knowledge Base'

  context 'header link color' do
    before do
      knowledge_base
      visit '/#manage/knowledge_base'
    end

    it 'shows color' do
      elem = find('#color_header_link input')

      expect(elem.value).to eq knowledge_base.color_header_link
    end

    it 'saves new color' do
      find('#color_header_link input').fill_in with: '#ccc'
      find('#color_header_link button').click

      await_empty_ajax_queue

      expect(knowledge_base.reload.color_header_link).to eq '#ccc'
    end
  end
end
