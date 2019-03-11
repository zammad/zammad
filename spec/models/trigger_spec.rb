require 'rails_helper'
require 'models/application_model_examples'

RSpec.describe Trigger, type: :model do
  it_behaves_like 'ApplicationModel', can_assets: { selectors: %i[condition perform] }

  before { Trigger.destroy_all }  # Default DB state includes three sample triggers
  subject!(:trigger) { create(:trigger, condition: condition, perform: perform) }

  describe '#assets (for supplying model data to front-end framework)' do
    let(:condition) { { 'ticket.state_id' => { operator: 'is', value: 1 } } }
    let(:perform) { { 'ticket.priority_id' => { value: 1 } } }

    it 'returns a hash with asset attributes for objects referenced in #condition and #perform' do
      expect(trigger.assets({}))
        .to include(Ticket::State.first.assets({}))
        .and include(Ticket::Priority.first.assets({}))
    end
  end

  describe 'Send-email triggers' do
    let(:perform) do
      {
        'notification.email' => {
          'recipient' => 'ticket_customer',
          'subject'   => 'foo',
          'body'      => 'bar'
        }
      }
    end

    context 'for condition "ticket created"' do
      let(:condition) do
        { 'ticket.action' => { 'operator' => 'is', 'value' => 'create' } }
      end

      context 'when ticket is created directly' do
        let!(:ticket) { create(:ticket) }

        it 'fires (without altering ticket state)' do
          expect { Observer::Transaction.commit }
            .to change { Ticket::Article.count }.by(1)
            .and not_change { ticket.reload.state.name }.from('new')
        end
      end

      context 'when ticket is created via Channel::EmailParser.process' do
        before { create(:email_address, groups: [Group.first]) }
        let(:raw_email) { File.read(Rails.root.join('test', 'data', 'mail', 'mail001.box')) }

        it 'fires (without altering ticket state)' do
          expect { Channel::EmailParser.new.process({}, raw_email) }
            .to change { Ticket.count }.by(1)
            .and change { Ticket::Article.count }.by(2)

          expect(Ticket.last.state.name).to eq('new')
        end
      end
    end

    context 'for condition "ticket updated"' do
      let(:condition) do
        { 'ticket.action' => { 'operator' => 'is', 'value' => 'update' } }
      end

      let!(:ticket) { create(:ticket).tap { Observer::Transaction.commit } }

      context 'when new article is created directly' do
        context 'with empty #preferences hash' do
          let!(:article) { create(:ticket_article, ticket: ticket)  }

          it 'fires (without altering ticket state)' do
            expect { Observer::Transaction.commit }
              .to change { ticket.reload.articles.count }.by(1)
              .and not_change { ticket.reload.state.name }.from('new')
          end
        end

        context 'with #preferences { "send-auto-response" => false }' do
          let!(:article) do
            create(:ticket_article,
                   ticket:      ticket,
                   preferences: { 'send-auto-response' => false })
          end

          it 'does not fire' do
            expect { Observer::Transaction.commit }
              .not_to change { ticket.reload.articles.count }
          end
        end
      end

      context 'when new article is created via Channel::EmailParser.process' do
        context 'with a regular message' do
          let!(:article) do
            create(:ticket_article,
                   ticket:     ticket,
                   message_id: raw_email[/(?<=^References: )\S*/],
                   subject:    raw_email[/(?<=^Subject: Re: ).*$/])
          end

          let(:raw_email) { File.read(Rails.root.join('test', 'data', 'mail', 'mail005.box')) }

          it 'fires (without altering ticket state)' do
            expect { Channel::EmailParser.new.process({}, raw_email) }
              .to not_change { Ticket.count }
              .and change { ticket.reload.articles.count }.by(2)
              .and not_change { ticket.reload.state.name }.from('new')
          end
        end

        context 'with delivery-failed "bounce message"' do
          let!(:article) do
            create(:ticket_article,
                   ticket:     ticket,
                   message_id: raw_email[/(?<=^Message-ID: )\S*/])
          end

          let(:raw_email) { File.read(Rails.root.join('test', 'data', 'mail', 'mail055.box')) }

          it 'does not fire' do
            expect { Channel::EmailParser.new.process({}, raw_email) }
              .to change { ticket.reload.articles.count }.by(1)
          end
        end
      end
    end
  end
end
