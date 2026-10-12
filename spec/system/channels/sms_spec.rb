# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Channels > SMS', type: :system do
  let(:public_key) { Base64.strict_encode64(OpenSSL::PKey.generate_key('ED25519').public_to_der.last(32)) }

  before { visit '/#channels/sms' }

  context 'when creating a Telnyx account channel' do
    it 'stores the provider configuration and shows it in the overview', :aggregate_failures do
      within :active_content do
        click '.js-channelEdit'
      end

      in_modal do
        select 'Telnyx', from: 'options::adapter'

        fill_in 'options::token',      with: 'KEY0123456789ABCDEF'
        fill_in 'options::public_key', with: public_key
        fill_in 'options::sender',     with: '+15551234567'
        set_tree_select_value('group_id', Group.first.name)

        click '.js-submit'
      end

      within :active_content do
        expect(page).to have_text('sms/telnyx')
        expect(page).to have_text('+15551234567')
      end

      channel = Channel.find_by(area: 'Sms::Account')
      expect(channel.group_id).to eq(Group.first.id)
      expect(channel.options).to include(
        'adapter'    => 'sms/telnyx',
        'token'      => 'KEY0123456789ABCDEF',
        'public_key' => public_key,
        'sender'     => '+15551234567',
      )
      expect(channel.options['webhook_token']).to be_present
    end
  end

  context 'when creating a Telnyx notification channel' do
    it 'stores the provider configuration', :aggregate_failures do
      within :active_content do
        click '.js-editNotification'
      end

      in_modal do
        select 'Telnyx', from: 'options::adapter'

        fill_in 'options::token',  with: 'KEY0123456789ABCDEF'
        fill_in 'options::sender', with: '+15551234567'

        click '.js-submit'
      end

      within :active_content do
        expect(page).to have_text('sms/telnyx')
      end

      expect(Channel.find_by(area: 'Sms::Notification').options).to include(
        'adapter' => 'sms/telnyx',
        'token'   => 'KEY0123456789ABCDEF',
        'sender'  => '+15551234567',
      )
    end
  end
end
