# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Channels > Email > Notification sender', type: :system do
  let(:usual_check_result)  { { result: 'ok' } }
  let(:test_address_result) { { result: 'ok' } }

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

    visit '#channels/email'

    find('.js-editNotificationOutbound').click

    in_modal disappears: false do
      find('[name=adapter] option[value=smtp]').select_option

      fill_in 'options::host',     with: 'smtp.example.com'
      fill_in 'options::user',     with: 'zammad'
      fill_in 'options::password', with: 'secret'
    end
  end

  context 'when the server accepts the test mail of the usual check' do
    it 'saves the sender without asking about an internal-only server' do
      in_modal do
        click_on 'Continue'
      end

      expect(EmailHelper::Probe).to have_received(:outbound).once
      expect(smtp_channel).to have_attributes(
        active:  true,
        options: include(outbound: include(internal_only: false, options: include(host: 'smtp.example.com'))),
      )
    end
  end

  context 'when the server refuses the test mail of the usual check' do
    let(:usual_check_result) { refusal }

    before do
      in_modal disappears: false do
        click_on 'Continue'
      end
    end

    it 'shows the refusal and asks about an internal-only server' do
      in_modal do
        expect(page).to have_css('.alert--danger', text: '554 5.7.1 Relay access denied')
          .and have_text('Does this email server only deliver to internal recipients?')
          .and have_no_field('test_address')
      end

      expect(smtp_channel).to have_attributes(active: false)
    end

    it 'takes the question back when the admin changes the password' do
      in_modal do
        fill_in 'options::password', with: 'another secret'

        expect(page).to have_no_text('Does this email server only deliver to internal recipients?')
      end
    end

    context 'when the admin confirms the question' do
      before do
        in_modal disappears: false do
          click_on 'Yes'
        end
      end

      it 'shows the note and the test address with the address of the admin' do
        in_modal do
          expect(page).to have_text('Please note that an internal-only email server may fail to deliver password reset, new device and similar system emails to recipients outside the organization.')
            .and have_no_text('Does this email server only deliver to internal recipients?')
            .and have_no_css('.alert--danger')
            .and have_field('test_address', with: 'admin@example.com')
            .and have_field('options::host', with: 'smtp.example.com')
            .and have_field('options::user', with: 'zammad')
            .and have_field('options::password', with: 'secret')
        end
      end

      it 'saves the sender as internal-only once the server accepts the mail to the test address' do
        in_modal do
          fill_in 'test_address', with: 'internal@example.com'

          click_on 'Continue'
        end

        expect(EmailHelper::Probe).to have_received(:outbound).with(anything, anything, hash_including(recipient: 'internal@example.com'))
        expect(smtp_channel).to have_attributes(
          active:  true,
          options: include(
            outbound: include(
              internal_only: true,
              options:       include(host: 'smtp.example.com', user: 'zammad', password: 'secret'),
            ),
          ),
        )
      end

      it 'takes a test address on a host without a domain' do
        in_modal do
          fill_in 'test_address', with: 'helpdesk@mailhost'

          click_on 'Continue'
        end

        expect(EmailHelper::Probe).to have_received(:outbound).with(anything, anything, hash_including(recipient: 'helpdesk@mailhost'))
      end

      it 'returns to the usual check when the admin switches the adapter' do
        in_modal do
          find('[name=adapter] option[value=sendmail]').select_option
          find('[name=adapter] option[value=smtp]').select_option

          expect(page).to have_field('options::host')
            .and have_no_field('test_address')
            .and have_no_text('Please note that an internal-only email server may fail')

          fill_in 'options::host', with: 'smtp.example.com'

          click_on 'Continue'

          expect(page).to have_text('Does this email server only deliver to internal recipients?')
        end

        expect(EmailHelper::Probe).not_to have_received(:outbound).with(anything, anything, hash_including(:recipient))
      end

      it 'returns to the usual check when the admin changes the host' do
        in_modal do
          fill_in 'options::host', with: 'smtp.example.org'

          expect(page).to have_no_field('test_address')
            .and have_no_text('Please note that an internal-only email server may fail')
            .and have_field('options::user', with: 'zammad')

          click_on 'Continue'

          expect(page).to have_text('Does this email server only deliver to internal recipients?')
        end

        expect(EmailHelper::Probe).not_to have_received(:outbound).with(anything, anything, hash_including(:recipient))
      end

      context 'when the server refuses the mail to the test address as well' do
        let(:test_address_result) { refusal }

        it 'shows the refusal without the question' do
          in_modal do
            click_on 'Continue'

            expect(page).to have_css('.alert--danger', text: '554 5.7.1 Relay access denied')
              .and have_no_text('Does this email server only deliver to internal recipients?')
              .and have_field('test_address', with: 'admin@example.com')
          end

          expect(smtp_channel).to have_attributes(active: false)
        end
      end
    end
  end

  context 'when the server refuses the test mail on a port without SSL verification' do
    let(:usual_check_result) { refusal }

    it 'keeps SSL verification off after the admin confirmed the question' do
      in_modal disappears: false do
        fill_in 'options::port', with: '25'

        click_on 'Continue'
        click_on 'Yes'

        expect(page).to have_field('test_address', with: 'admin@example.com')
          .and have_field('options::port', with: '25')
          .and have_field('options::ssl_verify', disabled: true)
      end

      in_modal do
        click_on 'Continue'
      end

      expect(smtp_channel.options.dig(:outbound, :options)).to include(port: '25', ssl_verify: false)
    end
  end

  context 'when the check fails for another reason' do
    let(:usual_check_result) do
      {
        result:        'invalid',
        message:       'getaddrinfo: Name or service not known',
        message_human: 'The hostname could not be found.',
        invalid_field: { host: true },
      }
    end

    it 'shows the error without the question' do
      in_modal do
        click_on 'Continue'

        expect(page).to have_css('.alert--danger', text: 'The hostname could not be found.')
          .and have_css('.form-group.has-error [name="options::host"]')
          .and have_no_text('Does this email server only deliver to internal recipients?')
      end
    end
  end
end
