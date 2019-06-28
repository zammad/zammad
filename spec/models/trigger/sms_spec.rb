require 'rails_helper'

RSpec.describe Trigger do

  describe 'sms' do

    it 'sends interpolated, html-free SMS' do
      agent = create(:agent_user)
      another_agent = create(:admin_user, mobile: '+37061010000')
      Group.lookup(id: 1).users << another_agent

      create(:channel, area: 'Sms::Notification')
      create(:trigger,
             disable_notification: false,
             perform:              {
               'notification.sms': {
                 recipient: 'ticket_agents',
                 body:      'space&nbsp;between #{ticket.title}', # rubocop:disable Lint/InterpolationCheck
               }
             })

      ticket = create(:ticket, group: Group.lookup(id: 1), created_by_id: agent.id)
      Observer::Transaction.commit

      triggered_article = Ticket::Article.last

      expect(triggered_article.body).to match(/space between/)
      expect(triggered_article.body).to match(ticket.title)
    end
  end
end
