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

    visit "#ticket/zoom/#{ticket.id}"
  end

  context 'when replying to a whatsapp message' do
    it 'allows to reply via whatsapp' do
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

  describe 'attachments limit' do
    it 'shows error message when switching from another type with multiple attachments' do
      within(:active_content) do
        find(:richtext).send_keys(sample_text)

        2.times do |i|
          find('input#fileUpload_1', visible: :all).set(Rails.root.join("spec/fixtures/files/image/squares#{i > 1 ? i.to_s : ''}.png"))
          expect(page).to have_text("squares#{i > 1 ? i.to_s : ''}.png")
        end

        click '.js-selectableTypes'
        click '.js-articleTypeItem[data-value="whatsapp message"]'

        expect(page).to have_text('Only 1 attachment allowed')

        within first('.attachment--row') do |elem|
          elem.execute_script('$(".attachment-delete", this).trigger("click")')
        end

        expect(page).to have_no_text('Only 1 attachment allowed')
      end
    end

    it 'does not allow to upload over the limit' do
      within(:active_content) do
        click_on 'reply'

        find('input#fileUpload_1', visible: :all).set(Rails.root.join('spec/fixtures/files/image/squares.png'))
        expect(page).to have_text('squares.png')

        # This click tests if file upload by button is disabled successfully.
        # If button is not disabled, it will crash with a file dialog being opened.
        expect { find('.fileUpload').click(wait: 0) }
          .to raise_error(Selenium::WebDriver::Error::ElementClickInterceptedError)

        # This upload attempt simulates drag&drop which could work even with the button disabled.
        find('input#fileUpload_1', visible: :all).set(Rails.root.join('spec/fixtures/files/image/squares2.png'))

        in_modal do
          expect(page).to have_text('Only 1 attachment allowed')
        end
      end
    end
  end

  describe 'caption disabling' do
    let(:audio_file) do
      # Tempfile does not work, because it appends auto-generated extension and breaks mimetype check
      tmp_file_path = Rails.root.join('tmp', "#{SecureRandom.uuid}.mp3")

      file = File.new(tmp_file_path, 'w')
      file.write(sample_text)
      file.close

      file
    end

    after { File.unlink audio_file.path }

    it 'disables caption when specific Whatsapp attachment is present' do
      within(:active_content) do
        find(:richtext).send_keys(sample_text)
        expect(find(:richtext)).to not_match_css('.text-muted')

        find('input#fileUpload_1', visible: :all).set(audio_file.path)

        click '.js-selectableTypes'
        click '.js-articleTypeItem[data-value="whatsapp message"]'

        expect(find(:richtext)).to match_css('.text-muted')

        within first('.attachment--row') do |elem|
          elem.execute_script('$(".attachment-delete", this).trigger("click")')
        end

        expect(find(:richtext)).to not_match_css('.text-muted')
      end
    end
  end

  describe 'with the customer service window information' do
    let(:article) do
      create(:whatsapp_article,
             from_phone_number:  ENV['WHATSAPP_RECIPIENT_NUMBER'],
             ticket:             ticket,
             timestamp_incoming: last_whatsapp_timestamp)
    end

    context 'when the window is open' do
      let(:last_whatsapp_timestamp) { 30.minutes.ago.to_i.to_s }

      it 'shows a warning alert with the text and humanized time' do
        within(:active_content) do
          expect(find('.scrollPageAlert')).to have_no_css('.hide')
            .and have_css('.alert--warning')
            .and have_text('You have a 24 hour window to send WhatsApp messages in this conversation. The customer service window closes in 23 hours.')
        end
      end
    end

    context 'when the window is closed' do
      let(:last_whatsapp_timestamp) { 24.hours.ago.to_i.to_s }

      it 'shows a danger alert with the text' do
        within(:active_content) do
          expect(find('.scrollPageAlert')).to have_no_css('.hide')
            .and have_css('.alert--danger')
            .and have_text('The 24 hour customer service window is now closed, no further WhatsApp messages can be sent.')
        end
      end
    end

    context 'when the timestamp is missing' do
      let(:last_whatsapp_timestamp) { nil }

      it 'keeps the alert container hidden' do
        within(:active_content) do
          expect(find('.scrollPageAlert', visible: :hide)).to be_present
        end
      end
    end

    context 'when the ticket is closed' do
      let(:ticket)                  { create(:whatsapp_ticket, channel: channel, state: Ticket::State.lookup(name: 'closed')) }
      let(:last_whatsapp_timestamp) { 30.minutes.ago.to_i.to_s }

      it 'keeps the alert container hidden' do
        within(:active_content) do
          expect(find('.scrollPageAlert', visible: :hide)).to be_present
        end
      end
    end
  end

  describe 'when connection errors occur', authenticated_as: :authenticate do
    let(:article) { create(:whatsapp_article, :with_attachment_media_document, from_phone_number: ENV['WHATSAPP_RECIPIENT_NUMBER'], ticket: ticket) }

    def authenticate
      allow_any_instance_of(Whatsapp::Retry::Media).to receive(:download_media).and_return(true)
      article.preferences['whatsapp']['media_error'] = true
      article.save!
      create(:agent, groups: Group.all)
    end

    it 'does retry the article attachments' do
      expect(page).to have_text('RETRY ATTACHMENT DOWNLOAD')
      click '.js-retryWhatsAppAttachmentDownload'
      expect(page).to have_no_text('RETRY ATTACHMENT DOWNLOAD')
    end
  end
end
