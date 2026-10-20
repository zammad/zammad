# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Ticket > Reply with inline image', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:ticket) { create(:ticket, group:) }
  let(:image)  { Rails.root.join('spec/fixtures/files/image/small.png').binread }
  let(:cid)    { '20260928.1234@zammad.example.com' }
  let(:article) do
    create(:ticket_article, :inbound_email, ticket:, content_type: 'text/html', body: "<p>Screenshot:</p><p><img src=\"cid:#{cid}\"></p>").tap do |article|
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        image,
             filename:    'screenshot.png',
             preferences: {
               'Content-Type'        => 'image/png',
               'Mime-Type'           => 'image/png',
               'Content-ID'          => "<#{cid}>",
               'Content-Disposition' => 'inline',
             })
    end
  end

  before do
    Setting.set('ui_ticket_zoom_article_email_full_quote', true)
    wait_for_setting('ui_ticket_zoom_article_email_full_quote', true)

    article
  end

  it 'gives the reply its own copy of the quoted image' do
    visit "/tickets/#{ticket.id}"

    wait_for_form_to_settle('form-ticket-edit')
    wait_for_gql('shared/entities/ticket/graphql/queries/ticket/articles.graphql')

    find_button('Article actions').click
    find_button('Reply').click

    wait.until do
      # The image appears asynchronously, `first` would wrap a missing one instead of returning nil.
      images = find_editor('Text').input_element.all('img:not(.ProseMirror-separator)', visible: :all, wait: false)
      images.first&.[](:src)&.match?(%r{/api/v1/attachments/\d+\z})
    end

    expect(page.evaluate_script("window.testFlags.get('editor.inlineImagesFailure', true)")).to be_falsey

    find_editor('Text').type('Please see below.')
    find_button('Save', wait: 20).click

    wait_for_gql('shared/entities/ticket/graphql/mutations/update.graphql')

    expect(ticket.articles.reload.last.attachments).to contain_exactly(have_attributes(content: image))
  end
end
