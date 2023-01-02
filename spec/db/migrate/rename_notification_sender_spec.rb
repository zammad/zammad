# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe RenameNotificationSender, type: :db_migration do
  before do
    Setting.find_by(name: 'notification_sender')&.destroy

    # Default value of Zammad 4.1
    Setting.create(
      title:       'Notification Sender',
      name:        'notification_sender',
      area:        'Email::Base',
      description: 'Defines the sender of email notifications.',
      options:     {
        form: [
          {
            display: '',
            null:    false,
            name:    'notification_sender',
            tag:     'input',
          },
        ],
      },
      state:       'Notification Master <noreply@#{config.fqdn}>', # rubocop:disable Lint/InterpolationCheck
      preferences: {
        online_service_disable: true,
        permission:             ['admin.channel_email'],
      },
      frontend:    false
    )
  end

  context 'when migrating unchanged default setting' do
    it 'sets new value' do
      expect { migrate }
        .to change { Setting.find_by(name: 'notification_sender').state_current }
        .to({ 'value' => '#{config.product_name} <noreply@#{config.fqdn}>' }) # rubocop:disable Lint/InterpolationCheck
    end

    it 'sets #state_initial' do
      expect { migrate }
        .to change { Setting.find_by(name: 'notification_sender').state_initial }
        .to({ 'value' => '#{config.product_name} <noreply@#{config.fqdn}>' }) # rubocop:disable Lint/InterpolationCheck
    end
  end

  context 'when migrating locally changed setting' do
    before do
      Setting.set('notification_sender', 'My Custom Sender <sender@local.domain>')
    end

    it 'does not change the current value' do
      expect { migrate }
        .not_to change { Setting.find_by(name: 'notification_sender').state_current }
    end

    it 'sets #state_initial' do
      expect { migrate }
        .to change { Setting.find_by(name: 'notification_sender').state_initial }
        .to({ 'value' => '#{config.product_name} <noreply@#{config.fqdn}>' }) # rubocop:disable Lint/InterpolationCheck
    end
  end

end
