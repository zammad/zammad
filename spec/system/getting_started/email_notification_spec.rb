# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Getting Started > Email Notification', type: :system do
  let(:usual_check_result)  { { result: 'ok' } }
  let(:test_address_result) { { result: 'ok' } }
  let(:container)           { false }

  let(:refusal) do
    {
      result:        'invalid',
      message:       'smtp.example.com: 554 5.7.1 Relay access denied',
      message_human: nil,
      invalid_field: {},
      refused:       true,
    }
  end

  def smtp_channel
    Channel.where(area: 'Email::Notification').to_a.find { it.options.dig(:outbound, :adapter) == 'smtp' }
  end

  before do
    results = { usual: usual_check_result, test_address: test_address_result }

    allow(EmailHelper::Probe).to receive(:outbound) do |*, recipient: nil, **|
      recipient ? results[:test_address] : results[:usual]
    end

    allow(Zammad::Deployment).to receive(:container?).and_return(container)

    visit 'getting_started/email_notification', skip_waiting: true

    within '.js-outbound' do
      find('[name=adapter] option[value=smtp]').select_option

      fill_in 'options::host', with: 'smtp.example.com'
      fill_in 'options::user', with: 'zammad'
    end
  end

  context 'when the server accepts the test mail of the usual check' do
    it 'saves the sender and continues without asking about an internal-only server' do
      click_on 'Continue'

      expect_current_route 'getting_started/channel'

      expect(EmailHelper::Probe).to have_received(:outbound).once
      expect(smtp_channel).to have_attributes(
        active:  true,
        options: include(outbound: include(internal_only: false, options: include(host: 'smtp.example.com'))),
      )
    end
  end

  context 'when the check ends with an error status' do
    before do
      allow(EmailHelper::Probe).to receive(:outbound).and_raise('The check ended unexpectedly.')

      click_on 'Continue'
    end

    it 'returns to the form with the error' do
      within '.js-outbound' do
        expect(page).to have_css('.alert--danger', text: 'The check ended unexpectedly.')
          .and have_field('options::host', with: 'smtp.example.com')
          .and have_button('Continue', disabled: false)
      end
    end
  end

  context 'when the server refuses the test mail of the usual check' do
    let(:usual_check_result) { refusal }

    before do
      click_on 'Continue'
    end

    it 'shows the refusal and asks about an internal-only server' do
      within '.js-outbound' do
        expect(page).to have_css('.alert--danger', text: '554 5.7.1 Relay access denied')
          .and have_text('Does this email server only deliver to internal recipients?')
          .and have_no_field('test_address')
      end

      expect(smtp_channel).to have_attributes(active: false)
    end

    context 'when the admin confirms the question' do
      before do
        click_on 'Yes'
      end

      it 'shows the note and the test address with the address of the admin' do
        within '.js-outbound' do
          expect(page).to have_text('Please note that an internal-only email server may fail to deliver password reset, new device and similar system emails to recipients outside the organization.')
            .and have_no_text('Does this email server only deliver to internal recipients?')
            .and have_field('test_address', with: 'admin@example.com')
            .and have_field('options::host', with: 'smtp.example.com')
        end
      end

      it 'saves the sender as internal-only and continues once the server accepts the mail to the test address' do
        click_on 'Continue'

        expect_current_route 'getting_started/channel'

        expect(EmailHelper::Probe).to have_received(:outbound).with(anything, anything, hash_including(recipient: 'admin@example.com'))
        expect(smtp_channel).to have_attributes(
          active:  true,
          options: include(outbound: include(internal_only: true, options: include(host: 'smtp.example.com'))),
        )
      end

      it 'returns to the usual check when the admin changes the user' do
        within '.js-outbound' do
          fill_in 'options::user', with: 'another'

          expect(page).to have_no_field('test_address')
            .and have_no_text('Please note that an internal-only email server may fail')
            .and have_field('options::host', with: 'smtp.example.com')
        end

        click_on 'Continue'

        expect(page).to have_text('Does this email server only deliver to internal recipients?')
        expect(EmailHelper::Probe).not_to have_received(:outbound).with(anything, anything, hash_including(:recipient))
      end

      context 'when the server refuses the mail to the test address as well' do
        let(:test_address_result) { refusal }

        it 'shows the refusal without the question' do
          click_on 'Continue'

          within '.js-outbound' do
            expect(page).to have_css('.alert--danger', text: '554 5.7.1 Relay access denied')
              .and have_no_text('Does this email server only deliver to internal recipients?')
              .and have_field('test_address', with: 'admin@example.com')
          end

          expect(smtp_channel).to have_attributes(active: false)
        end
      end
    end
  end

  # A container offers no sendmail, so the step is rendered with the SMTP form right away.
  context 'when the step is rendered again in a container after the admin confirmed the question' do
    let(:usual_check_result) { refusal }
    let(:container)          { true }

    before do
      click_on 'Continue'
      click_on 'Yes'
    end

    it 'starts with the usual check again' do
      within '.js-outbound' do
        expect(page).to have_field('test_address')
      end

      page.execute_script("App.Event.trigger('ui:rerender')")

      within '.js-outbound' do
        expect(page).to have_field('options::host', with: '')
          .and have_no_field('test_address')
          .and have_no_text('Please note that an internal-only email server may fail')
      end
    end
  end
end
