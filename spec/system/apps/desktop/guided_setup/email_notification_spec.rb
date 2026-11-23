# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Guided Setup > Email notification', app: :desktop_view, authenticated_as: :admin, type: :playwright do
  let(:admin)               { create(:admin, email: 'setup-admin@example.com') }
  let(:usual_check_result)  { { result: 'ok' } }
  let(:test_address_result) { { result: 'ok' } }

  let(:question) { 'Does this email server only deliver to internal recipients?' }
  let(:note)     { 'Please note that an internal-only email server may fail to deliver password reset, new device and similar system emails to recipients outside the organization.' }

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

  def button(name)
    page.get_by_role('button', name:, exact: true)
  end

  before do
    results = { usual: usual_check_result, test_address: test_address_result }

    allow(EmailHelper::Probe).to receive(:outbound) do |*, recipient: nil, **|
      recipient ? results[:test_address] : results[:usual]
    end

    open_desktop('/guided-setup/manual/email-notification')

    select_option('Send mails via', 'SMTP - configure your own outgoing SMTP settings')
    fill_field('Host', 'smtp.example.com')
    fill_field('User', 'zammad')
    fill_field('Password', 'secret')
    fill_field('Port', '587')
  end

  context 'when the server accepts the test email of the usual check' do
    it 'saves the sender and continues without asking about an internal-only server' do
      button('Save and continue').click

      expect(page.get_by_role('heading', name: 'Connect channels', level: 1)).to be_visible

      expect(EmailHelper::Probe).to have_received(:outbound).once
      expect(smtp_channel).to have_attributes(
        active:  true,
        options: include(outbound: include(internal_only: false, options: include(host: 'smtp.example.com'))),
      )
    end
  end

  context 'when the server refuses the test email of the usual check' do
    let(:usual_check_result) { refusal }

    before do
      button('Save and continue').click
    end

    it 'asks about an internal-only server and saves the sender as internal-only once the test address is accepted' do
      expect(notification('554 5.7.1 Relay access denied')).to be_visible
      expect(main_content).to contain_text(question)
      expect(page.get_by_label('Custom verification email', exact: true)).to have_count(0)

      button('Yes').click

      test_address = page.get_by_label('Custom verification email', exact: true)

      expect(test_address).to have_value('setup-admin@example.com')
      expect(test_address).to be_focused
      expect(main_content).to contain_text(note)
      expect(main_content).to not_contain_text(question)
      expect(notification('554 5.7.1 Relay access denied')).to have_count(0)

      button('Save and continue').click

      expect(page.get_by_role('heading', name: 'Connect channels', level: 1)).to be_visible

      expect(EmailHelper::Probe).to have_received(:outbound).with(anything, anything, hash_including(recipient: 'setup-admin@example.com'))
      expect(smtp_channel).to have_attributes(
        active:  true,
        options: include(outbound: include(internal_only: true, options: include(host: 'smtp.example.com'))),
      )
    end

    context 'when the server refuses the email to the test address as well' do
      let(:test_address_result) { refusal }

      it 'shows the refusal without the question' do
        button('Yes').click

        expect(page.get_by_label('Custom verification email', exact: true)).to be_visible

        button('Save and continue').click

        expect(notification('554 5.7.1 Relay access denied')).to be_visible
        expect(main_content).to not_contain_text(question)
        expect(main_content).to contain_text(note)
        expect(smtp_channel).to have_attributes(active: false)
      end
    end
  end
end
