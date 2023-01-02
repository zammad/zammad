# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Article Image View', type: :system do
  describe 'Switching the photos displayed in the preview' do
    let(:ticket) { create(:ticket, group: Group.first) }
    let(:article) do
      create(:ticket_article, ticket: ticket, attachments: [
               {
                 data:        Rails.root.join('spec/fixtures/files/image/large.png').read,
                 filename:    'large.png',
                 preferences: { 'Content-Type' => 'image/png', 'resizable' => true, 'content_preview' => true },
               },
               {
                 data:        Rails.root.join('spec/fixtures/files/image/large2.png').read,
                 filename:    'large2.png',
                 preferences: { 'Content-Type' => 'image/png', 'resizable' => true, 'content_preview' => true },
               },
               {
                 data:        Rails.root.join('spec/fixtures/files/image/large3.png').read,
                 filename:    'large3.png',
                 preferences: { 'Content-Type' => 'image/png', 'resizable' => true, 'content_preview' => true },
               },
             ])
    end

    def current_scroll_position
      find('div.modal').evaluate_script('this.scrollTop')
    end

    before do
      visit "#ticket/zoom/#{article.ticket.id}"
    end

    # https://github.com/zammad/zammad/issues/4030
    it 'does switch images via arrow keys' do
      first('.ticket-article-item .js-preview').click
      images = Store.last(3)
      wait.until { page.find('div.imagePreview img')[:src].include?("/#{images[0].id}") }
      find('body').send_keys :arrow_right
      wait.until { page.find('div.imagePreview img')[:src].include?("/#{images[1].id}") }
      find('body').send_keys :arrow_right
      wait.until { page.find('div.imagePreview img')[:src].include?("/#{images[2].id}") }
      find('body').send_keys :arrow_left
      wait.until { page.find('div.imagePreview img')[:src].include?("/#{images[1].id}") }
    end
  end
end
