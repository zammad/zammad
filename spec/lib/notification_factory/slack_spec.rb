# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe NotificationFactory::Slack do
  describe '.template' do
    subject(:template) do
      described_class.template(
        template: action,
        locale:   'en-us',
        timezone: 'Europe/Berlin',
        objects:  {
          ticket:       ticket,
          article:      article,
          recipient:    agent,
          current_user: current_user,
          changes:      changes,
        }
      )
    end

    let(:ticket) { article.ticket }
    let(:article) { create(:ticket_article) }
    let(:agent) { create(:agent) }
    let(:current_user) { create(:agent) }

    context 'for "ticket_create", with an empty "changes" hash' do
      let(:action) { 'ticket_create' }

      let(:changes) { {} }

      it 'returns a hash with subject: <ticket title> (as Markdown heading)' do
        expect(template).to include(subject: "# #{ticket.title}")
      end

      it 'returns a hash with body: <article author & body>' do
        expect(template[:body])
          .to match(%r{Created by #{current_user.fullname}})
          .and match(%r{#{article.body}\z})
      end
    end

    context 'for "ticket_update", with a populated "changes" hash' do
      let(:action) { 'ticket_update' }

      let(:changes) do
        {
          state:        %w[aaa bbb],
          group:        %w[xxx yyy],
          pending_time: [Time.zone.parse('2019-04-01T10:00:00Z0'), Time.zone.parse('2019-04-01T23:00:00Z0')],
        }
      end

      it 'returns a hash with subject: <ticket title> (as Markdown heading)' do
        expect(template).to include(subject: "# #{ticket.title}")
      end

      it 'returns a hash with body: <article editor, changes, & body>' do
        expect(template[:body])
          .to match(%r{Updated by #{current_user.fullname}})
          .and match(%r{state: aaa -> bbb})
          .and match(%r{group: xxx -> yyy})
          .and match(%r{pending_time: 04/01/2019 12:00 \(Europe/Berlin\) -> 04/02/2019 01:00 \(Europe/Berlin\)})
          .and match(%r{#{article.body}\z})
      end
    end

    context 'for "ticket_escalate"' do
      subject(:template) do
        described_class.template(
          template: 'ticket_escalation',
          locale:   'en-us',
          timezone: 'Europe/Berlin',
          objects:  {
            ticket:    ticket,
            article:   article,
            recipient: agent,
          }
        )
      end

      before { ticket.escalation_at = escalation_time }

      let(:escalation_time) { Time.zone.parse('2019-04-01T10:00:00Z') }

      it 'returns a hash with subject: <ticket title> (as Markdown heading)' do
        expect(template).to include(subject: "# #{ticket.title}")
      end

      it 'returns a hash with body: <ticket customer, escalation time, & body>' do
        expect(template[:body])
          .to match(%r{A ticket \(#{ticket.title}\) from "#{ticket.customer.fullname}"})
          .and match(%r{is escalated since "04/01/2019 12:00 \(Europe/Berlin\)"!})
          .and match(%r{#{article.body}\z})
      end
    end
  end
end
