# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Zoom > Whatsapp reply', :use_vcr, authenticated_as: :user, performs_jobs: true, required_envs: %w[WHATSAPP_ACCESS_TOKEN WHATSAPP_APP_SECRET WHATSAPP_BUSINESS_ID WHATSAPP_PHONE_NUMBER WHATSAPP_PHONE_NUMBER_ID WHATSAPP_PHONE_NUMBER_NAME WHATSAPP_RECIPIENT_NUMBER], type: :system do
  let(:article)     { create(:whatsapp_article, from_phone_number: ENV['WHATSAPP_RECIPIENT_NUMBER'], ticket: ticket) }
  let(:ticket)      { create(:whatsapp_ticket, channel: channel) }
  let(:user)        { create(:agent, groups: [ticket.group]) }
  let(:sample_text) { 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.' }

  let(:channel) do
    create(:whatsapp_channel,
           business_id:     ENV['WHATSAPP_BUSINESS_ID'],
           access_token:    ENV['WHATSAPP_ACCESS_TOKEN'],
           phone_number_id: ENV['WHATSAPP_PHONE_NUMBER_ID'],
           phone_number:    ENV['WHATSAPP_PHONE_NUMBER'],
           name:            ENV['WHATSAPP_PHONE_NUMBER_NAME'],
           app_secret:      ENV['WHATSAPP_APP_SECRET'])
  end

  before do
    article
  end

  context 'when replying to a whatsapp message' do
    it 'allows to reply via whatsapp' do
      visit "#ticket/zoom/#{ticket.id}"

      within(:active_content) do
        click_on 'reply'
        find(:richtext).send_keys(sample_text)
        click '.js-submit'

        expect(page).to have_css('.textBubble', text: sample_text)
      end

      perform_enqueued_jobs

      expect(Ticket::Article.last).to have_attributes(
        type:        have_attributes(name: 'whatsapp message'),
        preferences: include(
          delivery_status: 'success',
        ),
      )
    end
  end
end
