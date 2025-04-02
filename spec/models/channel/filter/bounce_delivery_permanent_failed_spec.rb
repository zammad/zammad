# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::BounceDeliveryPermanentFailed, type: :channel_filter do
  describe 'Notification loops because mail bouncing timeouts do not apply to users in system notifications #5428', performs_jobs: true, sends_notification_emails: true do
    let(:random_agent) { create(:agent, groups: [Group.first]) }
    let(:dead_agent)   { create(:agent, email: 'not_existing@znuny.com', groups: [Group.first]) }
    let(:ticket)       { create(:ticket, number: '10010', owner: dead_agent, group: Group.first) }
    let(:failed_eml)   { Rails.root.join('test/data/mail/mail033-undelivered-mail-returned-to-sender-notification.box').read.sub('1.4.5f4fd063-f69b-4e64-a92d-5e7128bd6682', "#{ticket.id}.#{dead_agent.id}.5f4fd063-f69b-4e64-a92d-5e7128bd6682") }

    context 'when match' do
      before do
        travel_to Time.zone.parse('Sun, 29 Aug 2015 16:56:00 +0200')
        ticket
        TransactionDispatcher.commit
        perform_enqueued_jobs
        travel_to Time.zone.parse('Sun, 30 Aug 2015 16:56:00 +0200') # does match with history
      end

      it 'does find the agent based on the system notifications and disables him for mail delivery', :aggregate_failures do
        UserInfo.current_user_id = random_agent.id

        check_notification do
          ticket.update!(priority: Ticket::Priority.find_by(name: '3 high'))
          TransactionDispatcher.commit
          perform_enqueued_jobs

          sent(
            template: 'ticket_update',
            user:     dead_agent,
          )
        end
        travel_back

        mail = Channel::EmailParser.new.parse(failed_eml, allow_missing_attribute_exceptions: true | false)
        filter(mail)
        expect(dead_agent.reload.preferences[:mail_delivery_failed]).to be(true)
        expect(dead_agent.reload.preferences[:mail_delivery_failed_data]).to be_present

        check_notification do
          ticket.update!(priority: Ticket::Priority.find_by(name: '1 low'))
          TransactionDispatcher.commit
          perform_enqueued_jobs

          not_sent(
            template: 'ticket_update',
            user:     dead_agent,
          )
        end
      end
    end

    context 'when no match' do
      before do
        travel_to Time.zone.parse('Sun, 29 Aug 2015 17:56:00 +0200')
        ticket
        TransactionDispatcher.commit
        perform_enqueued_jobs
        travel_to Time.zone.parse('Sun, 30 Aug 2015 18:56:00 +0200') # does not match with history
      end

      it 'does not find the agent based on the system notifications and continues mail delivery', :aggregate_failures do
        UserInfo.current_user_id = random_agent.id

        check_notification do
          ticket.update!(priority: Ticket::Priority.find_by(name: '3 high'))
          TransactionDispatcher.commit
          perform_enqueued_jobs

          sent(
            template: 'ticket_update',
            user:     dead_agent,
          )
        end
        travel_back

        mail = Channel::EmailParser.new.parse(failed_eml, allow_missing_attribute_exceptions: true | false)
        filter(mail)
        expect(dead_agent.reload.preferences[:mail_delivery_failed]).to be_blank
        expect(dead_agent.reload.preferences[:mail_delivery_failed_data]).to be_blank

        check_notification do
          ticket.update!(priority: Ticket::Priority.find_by(name: '1 low'))
          TransactionDispatcher.commit
          perform_enqueued_jobs

          sent(
            template: 'ticket_update',
            user:     dead_agent,
          )
        end
      end
    end
  end
end
