# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Article Image View', type: :system do
  describe 'Switching the photos displayed in the preview does not work with the arrow keys #4030' do
    let(:ticket) { create(:ticket, group: Group.first) }
    let(:article) do
      create(:ticket_article, ticket: ticket, attachments: [
               {
                 data:        File.read(Rails.root.join('spec/fixtures/files/image/squares.png')),
                 filename:    'squares.png',
                 preferences: { 'Content-Type' => 'image/png', 'resizable' => true, 'content_preview' => true },
               },
               {
                 data:        File.read(Rails.root.join('spec/fixtures/files/image/squares2.png')),
                 filename:    'squares2.png',
                 preferences: { 'Content-Type' => 'image/png', 'resizable' => true, 'content_preview' => true },
               },
               {
                 data:        File.read(Rails.root.join('spec/fixtures/files/image/squares3.png')),
                 filename:    'squares3.png',
                 preferences: { 'Content-Type' => 'image/png', 'resizable' => true, 'content_preview' => true },
               },
             ])
    end

    before do
      visit "#ticket/zoom/#{article.ticket.id}"
    end

    it 'does switch images via arrow keys' do
      first('.ticket-article-item .js-preview').click
      images = Store.last(3)
      expect(page.find('div.imagePreview img')[:src]).to include("/#{images[0].id}")
      find('body').send_keys :arrow_right
      find('body').send_keys :arrow_right
      expect(page.find('div.imagePreview img')[:src]).to include("/#{images[2].id}")
      find('body').send_keys :arrow_left
      expect(page.find('div.imagePreview img')[:src]).to include("/#{images[1].id}")
    end
  end
end
