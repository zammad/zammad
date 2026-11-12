# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Reply with inline image', app: :desktop_view, authenticated_as: :agent, type: :playwright do
  let(:group)    { create(:group) }
  let(:agent)    { create(:agent, groups: [group]) }
  let(:ticket)   { create(:ticket, group:, title: 'Inline image test') }
  let(:image)    { Rails.root.join('spec/fixtures/files/image/small.png').binread }
  let(:cid)      { '20260928.1234@zammad.example.com' }
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

  def reply_to_article
    ticket_article('Screenshot:').get_by_role('button', name: 'Reply', exact: true).click
  end

  # The quoted image is uploaded again for the reply, it shows the copy once it is done.
  def quoted_image_src
    image = editor('Text').get_by_role('img').first
    expect(image).to have_attribute('src', %r{/api/v1/attachments/\d+$})

    image.get_attribute('src')
  end

  def inline_images_failure?
    test_flag_set?('editor.inlineImagesFailure')
  end

  def upload_cache_items
    Store.where(store_object: Store::Object.lookup(name: 'UploadCache'), created_by_id: agent.id)
  end

  def submit_reply
    page.get_by_role('button', name: 'Update', exact: true).click

    expect(notification('Ticket updated successfully.')).to be_visible
  end

  before do
    Setting.set('ui_ticket_zoom_article_email_full_quote', true)

    article
  end

  it 'gives the reply its own copy of the quoted image' do
    open_desktop_ticket(ticket)
    reply_to_article

    expect(quoted_image_src).to end_with("/api/v1/attachments/#{upload_cache_items.sole.id}")
    expect(inline_images_failure?).to be_falsey

    type_in_editor('Text', 'Please see below.')
    submit_reply

    reply = ticket.articles.reload.last

    expect(reply.attachments).to contain_exactly(have_attributes(content: image, preferences: include('Content-Disposition' => 'inline')))

    article.destroy!

    expect(reply.reload.attachments.sole.content).to eq(image)
  end

  context 'when the ticket is opened from an online notification and the group has a signature' do
    let(:group)               { create(:group, signature: create(:signature)) }
    let(:other_agent)         { create(:agent, groups: [group]) }
    let(:online_notification) { create(:online_notification, user: agent, created_by: other_agent, updated_by: other_agent, o: ticket, type_name: 'create') }

    before do
      online_notification

      open_desktop('/')

      page.get_by_role('button', name: 'Show notifications').click
      page.get_by_role('link', name: "#{other_agent.fullname} created ticket").click

      wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")
    end

    it 'uploads the quoted image once on the first attempt' do
      reply_to_article
      wait_for_test_flag('editor.signatureAdd')

      expect(quoted_image_src).to end_with("/api/v1/attachments/#{upload_cache_items.sole.id}")
      expect(inline_images_failure?).to be_falsey
    end
  end

  context 'with the same ticket open in another browser tab' do
    let(:other_tab) { open_tab }

    before do
      open_desktop_ticket(ticket)
      wait_for_subscription_start('userCurrentTaskbarItemStateUpdates')

      on_tab(other_tab) do
        open_desktop_ticket(ticket)
        wait_for_subscription_start('userCurrentTaskbarItemStateUpdates')
      end
    end

    it 'uploads the quoted image once and creates one attachment per image' do
      reply_to_article

      src = quoted_image_src

      on_tab(other_tab) do
        expect(quoted_image_src).to eq(src)
        expect(upload_cache_items.count).to eq(1)

        submit_reply
      end

      expect(ticket.articles.reload.last.attachments).to contain_exactly(have_attributes(content: image))

      # The sent draft is reset in this tab as well, so nothing points at its removed copies anymore.
      expect(page.locator('img[src*="/api/v1/attachments/"]')).to have_count(0)
    end
  end
end
