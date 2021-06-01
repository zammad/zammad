# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Trigger do

  describe 'sms' do
    before do
      Translation.fetch(locale)
      Setting.set('locale_default', locale)
      Setting.set('timezone_default', time_zone)
    end

    let(:time_zone) { 'Europe/Vilnius' }
    let(:locale) { 'de-de' }

    context 'sends interpolated, html-free SMS' do
      before do
        another_agent = create(:admin, mobile: '+37061010000')
        Group.lookup(id: 1).users << another_agent

        create(:channel, area: 'Sms::Notification')
        create(:trigger,
               disable_notification: false,
               perform:              {
                 'notification.sms': {
                   recipient: 'ticket_agents',
                   body:      message_body,
                 }
               })
      end

      let(:message_body) { 'space&nbsp;between #{ticket.title} #{ticket.created_at}' } # rubocop:disable Lint/InterpolationCheck

      let(:agent) { create(:agent) }
      let(:ticket) do
        ticket = create(:ticket, group: Group.lookup(id: 1), created_by_id: agent.id)
        TransactionDispatcher.commit
        ticket
      end

      let(:triggered_article) do
        ticket.articles.last
      end

      it 'renders HTML chars' do
        expect(triggered_article.body).to match(%r{space between})
      end

      it 'interpolates ticket properties' do
        expect(triggered_article.body).to match(ticket.title)
      end

      it 'interpolates time in selected time zone' do
        time_in_zone = triggered_article.ticket.created_at.in_time_zone(time_zone)

        expect(triggered_article.body).to match(time_in_zone.strftime('%H:%M'))
      end

      it 'interpolates date in selected locale format' do
        time_in_zone = triggered_article.ticket.created_at.in_time_zone(time_zone)

        expect(triggered_article.body).to match(time_in_zone.strftime('%d.%m.%Y'))
      end
    end

    context 'recipients' do

      let(:recipient1) { create(:agent, mobile: '+37061010000', groups: [ticket_group]) }
      let(:recipient2) { create(:agent, mobile: '+37061010001', groups: [ticket_group]) }
      let(:recipient3) { create(:agent, mobile: '+37061010002', groups: [ticket_group]) }

      let(:ticket_group) { create(:group) }

      let(:ticket) do
        ticket = create(:ticket, group: ticket_group, created_by_id: create(:agent).id)
        TransactionDispatcher.commit
        ticket
      end

      before do
        create(:channel, area: 'Sms::Notification')
        create(:trigger,
               disable_notification: false,
               perform:              {
                 'notification.sms': {
                   recipient: ['ticket_agents', "userid_#{recipient1.id}", "userid_#{recipient2.id}", "userid_#{recipient3.id}"],
                   body:      'Hello World!',
                 }
               })
      end

      it 'contains no duplicates' do
        expect(ticket.articles.last.preferences['sms_recipients'].sort).to eq([recipient1.mobile, recipient2.mobile, recipient3.mobile].sort)
      end
    end
  end
end
