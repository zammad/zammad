require 'rails_helper'

RSpec.describe Trigger do

  describe 'sms' do

    it 'sends interpolated, html-free SMS' do
      customer = create(:customer_user)
      agent = create(:agent_user)
      another_agent = create(:admin_user, mobile: '+37061010000')
      Group.lookup(id: 1).users << another_agent

      channel = create(:channel, area: 'Sms::Notification')
      trigger = create(:trigger,
                       disable_notification: false,
                       perform: {
                         'notification.sms': {
                           recipient: 'ticket_agents',
                           body:      'space&nbsp;between #{ticket.title}', # rubocop:disable Lint/InterpolationCheck
                         }
                       })

      ticket = create(:ticket, customer: customer, created_by_id: agent.id)
      Observer::Transaction.commit

      triggered_article = Ticket::Article.last

      expect(triggered_article.body.match?(/space between/)).to be_truthy
      expect(triggered_article.body.match?(ticket.title)).to be_truthy
    end
  end
end
