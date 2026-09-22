# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/http_log_examples'

# One entry per screen embedding App.HttpLog, so a new facility gets its coverage added here.
# hash_content marks the facilities whose backends store a structure rather than the raw payload:
# the Exchange token refresh and contact import, the LDAP user import and the WhatsApp webhook.
RSpec.describe 'HTTP log widget', type: :system do
  describe 'AI > Feedback & Logs' do
    include_examples 'HTTP log', facility: 'AI::Provider', path: '#ai/feedback_logs'
  end

  # The list screens draw their log only once there is something in the list.
  describe 'Manage > Webhook' do
    before { create(:webhook) }

    include_examples 'HTTP log', facility: 'webhook', path: '#manage/webhook'
  end

  describe 'Channels > WhatsApp' do
    before { create(:whatsapp_channel) }

    include_examples 'HTTP log', facility: 'WhatsApp::Business', path: '#channels/whatsapp', hash_content: true
  end

  describe 'System > Integrations > Checkmk' do
    include_examples 'HTTP log', facility: 'check_mk', path: '#system/integration/check_mk'
  end

  describe 'System > Integrations > Clearbit' do
    include_examples 'HTTP log', facility: 'clearbit', path: '#system/integration/clearbit'
  end

  describe 'System > Integrations > CTI (generic)' do
    include_examples 'HTTP log', facility: 'cti', path: '#system/integration/cti'
  end

  describe 'System > Integrations > Exchange' do
    include_examples 'HTTP log', facility: 'EWS', path: '#system/integration/exchange', hash_content: true
  end

  describe 'System > Integrations > i-doit' do
    include_examples 'HTTP log', facility: 'idoit', path: '#system/integration/idoit'
  end

  describe 'System > Integrations > LDAP' do
    include_examples 'HTTP log', facility: 'ldap', path: '#system/integration/ldap', hash_content: true
  end

  describe 'System > Integrations > PGP' do
    include_examples 'HTTP log', facility: 'PGP', path: '#system/integration/pgp'
  end

  describe 'System > Integrations > Placetel' do
    include_examples 'HTTP log', facility: 'placetel', path: '#system/integration/placetel'
  end

  describe 'System > Integrations > S/MIME' do
    include_examples 'HTTP log', facility: 'S/MIME', path: '#system/integration/smime'
  end

  describe 'System > Integrations > sipgate.io' do
    include_examples 'HTTP log', facility: 'sipgate.io', path: '#system/integration/sipgate'
  end

end
