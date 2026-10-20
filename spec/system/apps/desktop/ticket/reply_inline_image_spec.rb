# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Reply with inline image', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:group)    { create(:group) }
  let(:agent)    { create(:agent, password: 'test', groups: [group]) }
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

  def open_ticket
    visit "/tickets/#{ticket.id}"

    wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")
  end

  def reply_to_article
    within "#article-#{article.id}" do
      find('button', exact_text: 'Reply', visible: :all).click
    end
  end

  def quoted_image_src
    src = nil

    wait.until do
      # The image appears asynchronously, `first` would wrap a missing one instead of returning nil.
      images = find_editor('Text').input_element.all('img:not(.ProseMirror-separator)', visible: :all, wait: false)
      src    = images.first&.[](:src)
      src&.match?(%r{/api/v1/attachments/\d+\z})
    end

    src
  end

  def upload_cache_items
    Store.where(store_object: Store::Object.lookup(name: 'UploadCache'), created_by_id: agent.id)
  end

  def submit_reply
    click_on 'Update'

    wait_for_gql('shared/entities/ticket/graphql/mutations/update.graphql')
  end

  before do
    Setting.set('ui_ticket_zoom_article_email_full_quote', true)
    wait_for_setting('ui_ticket_zoom_article_email_full_quote', true)

    article
  end

  it 'gives the reply its own copy of the quoted image' do
    open_ticket
    reply_to_article

    expect(quoted_image_src).to end_with("/api/v1/attachments/#{upload_cache_items.sole.id}")
    expect(page.evaluate_script("window.testFlags.get('editor.inlineImagesFailure', true)")).to be_falsey

    find_editor('Text').type('Please see below.')
    submit_reply

    reply = ticket.articles.reload.last

    expect(reply.attachments).to contain_exactly(have_attributes(content: image, preferences: include('Content-Disposition' => 'inline')))

    article.destroy!

    expect(reply.reload.attachments.sole.content).to eq(image)
  end

  context 'when the ticket is opened from an online notification and the group has a signature' do
    let(:group)        { create(:group, signature: create(:signature)) }
    let(:other_agent)  { create(:agent, groups: [group]) }
    let(:notification) { create(:online_notification, user: agent, created_by: other_agent, updated_by: other_agent, o: ticket, type_name: 'create') }

    before do
      notification

      visit '/'
      wait_for_subscription_update('onlineNotificationsCount', number: 1)

      find('button[aria-label="Show notifications"]').click

      within('[role="region"]') do
        click_on "#{other_agent.fullname} created ticket"
      end

      wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")
    end

    it 'uploads the quoted image once on the first attempt' do
      reply_to_article
      wait_for_test_flag('editor.signatureAdd')

      expect(quoted_image_src).to end_with("/api/v1/attachments/#{upload_cache_items.sole.id}")
      expect(page.evaluate_script("window.testFlags.get('editor.inlineImagesFailure', true)")).to be_falsey
    end
  end

  context 'with the same ticket open in another browser tab' do
    before do
      open_ticket
      wait_for_subscription_start('userCurrentTaskbarItemStateUpdates')

      using_session(:other_tab) do
        login(username: agent.login, password: 'test')
        open_ticket
        wait_for_subscription_start('userCurrentTaskbarItemStateUpdates')
      end
    end

    it 'uploads the quoted image once and creates one attachment per image' do
      reply_to_article

      src = quoted_image_src

      using_session(:other_tab) do
        expect(quoted_image_src).to eq(src)
        expect(upload_cache_items.count).to eq(1)

        submit_reply
      end

      expect(ticket.articles.reload.last.attachments).to contain_exactly(have_attributes(content: image))

      # The sent draft is reset in this tab as well, so nothing points at its removed copies anymore.
      expect(page).to have_no_css('img[src*="/api/v1/attachments/"]', visible: :all)
    end
  end
end
