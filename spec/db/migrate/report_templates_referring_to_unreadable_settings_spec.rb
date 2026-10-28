# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ReportTemplatesReferringToUnreadableSettings, type: :db_migration do
  let!(:trigger)     { create(:trigger, name: 'Affected trigger', perform: { 'article.note' => { 'subject' => 'Note', 'internal' => 'true', 'body' => 'Up to #{<span>config.postmaster_max_size</span>} MB' } }) }
  let!(:text_module) { create(:text_module, name: 'Affected text module', content: 'Key #{config.application_secret} and #{config.application_secret}') } # rubocop:disable Lint/InterpolationCheck
  let!(:text_tool)   { create(:ai_text_tool, name: 'Affected text tool', instruction: 'Mention #{config.es_password}') } # rubocop:disable Lint/InterpolationCheck
  let!(:agent)       { create(:ai_agent, name: 'Affected agent', agent_type: 'TicketCategorizer', type_enrichment_data: { 'category' => '#{config.es_password}' }) } # rubocop:disable Lint/InterpolationCheck
  let!(:attribute) do
    create(:object_manager_attribute_text, name: 'affected_link').tap do |attribute|
      attribute.update_column(:data_option, attribute.data_option.merge('linktemplate' => 'https://crm.example/#{config.proxy_password}')) # rubocop:disable Lint/InterpolationCheck
    end
  end

  before do
    create(:setting, name: 'affected_setting', state: 'test')
    Setting.set('affected_setting', 'Sender #{config.application_secret}') # rubocop:disable Lint/InterpolationCheck
    create(:setting, name: 'public_setting', frontend: true, state: 'test')
    Setting.set('public_setting', 'ID #{config.system_id} at #{config.fqdn}') # rubocop:disable Lint/InterpolationCheck
    create(:setting, name: 'authenticated_setting', frontend: true, preferences: { authentication: true }, state: 'test')
    Setting.set('authenticated_setting', 'ID #{config.system_id}') # rubocop:disable Lint/InterpolationCheck
    create(:signature, name: 'Fine signature', body: '#{config.product_name} at #{config.fqdn}, #{config.ticket_hook_divider}, #{config.produkt_name}, \#{config.application_secret}') # rubocop:disable Lint/InterpolationCheck
    allow(Rails.logger).to receive(:warn)
  end

  it 'logs every template that refers to a setting templates no longer resolve, as the renderer parses it, once per setting, and not an unknown name or an escaped placeholder', :aggregate_failures do
    migrate

    expect(Rails.logger).to have_received(:warn).with("Templates referring to settings: Trigger 'Affected trigger' (id #{trigger.id}) refers to settings templates no longer resolve: postmaster_max_size. Replace the placeholders, they render as missing objects.")
    expect(Rails.logger).to have_received(:warn).with("Templates referring to settings: TextModule 'Affected text module' (id #{text_module.id}) refers to settings templates no longer resolve: application_secret. Replace the placeholders, they render as missing objects.")
    expect(Rails.logger).to have_received(:warn).with("Templates referring to settings: AI::TextTool 'Affected text tool' (id #{text_tool.id}) refers to settings templates no longer resolve: es_password. Replace the placeholders, they render as missing objects.")
    expect(Rails.logger).to have_received(:warn).with("Templates referring to settings: AI::Agent 'Affected agent' (id #{agent.id}) refers to settings templates no longer resolve: es_password. Replace the placeholders, they stay unresolved in the prompt.")
    expect(Rails.logger).to have_received(:warn).with("Templates referring to settings: ObjectManager::Attribute 'Ticket#affected_link' (id #{attribute.id}) refers to settings templates no longer resolve: proxy_password. Replace the placeholders, they render as missing objects.")
    expect(Rails.logger).to have_received(:warn).with("Templates referring to settings: Setting 'affected_setting' (id #{Setting.find_by(name: 'affected_setting').id}) refers to settings its value no longer takes in: application_secret. Replace the placeholders, they are dropped from the value.")
    expect(Rails.logger).to have_received(:warn).with("Templates referring to settings: Setting 'public_setting' (id #{Setting.find_by(name: 'public_setting').id}) refers to settings its value no longer takes in: system_id. Replace the placeholders, they are dropped from the value.")
    expect(Rails.logger).not_to have_received(:warn).with(%r{Signature})
    expect(Rails.logger).not_to have_received(:warn).with(%r{Setting 'authenticated_setting'})
    expect(Rails.logger).not_to have_received(:warn).with(%r{Setting 'notification_sender'})
  end
end
