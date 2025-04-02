# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(Webhook::PreDefined) do
  it 'checks that pre defined webhook list can be used' do
    expect(described_class.pre_defined_webhooks.sort_by(&:name)).to include(
      Webhook::PreDefined::Mattermost,
      Webhook::PreDefined::MicrosoftTeams,
      Webhook::PreDefined::RocketChat,
      Webhook::PreDefined::Slack
    )
  end

  context 'when definition is used' do
    let(:slack_custom_payload) do
      # rubocop:disable Lint/InterpolationCheck
      JSON.pretty_generate({
                             mrkdwn:      true,
                             text:        '# #{ticket.title}',
                             attachments: [
                               {
                                 text:      "_[Ticket#\#{ticket.number}](\#{notification.link}): \#{notification.message}_\n\n\#{notification.changes}\n\n\#{notification.body}",
                                 mrkdwn_in: [
                                   'text'
                                 ],
                                 color:     '#{ticket.current_state_color}'
                               }
                             ]
                           })
      # rubocop:enable Lint/InterpolationCheck
    end

    it 'checks that pre defined webhook definitions are returned' do
      expect(described_class.pre_defined_webhook_definitions.find { |item| item[:id] == 'Slack' }).to include(
        id:             'Slack',
        name:           'Slack Notifications',
        custom_payload: include(slack_custom_payload),
        fields:         [],
      )
    end
  end
end
