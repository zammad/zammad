# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Article::Create, current_user_id: -> { user.id } do
  subject(:service) { described_class.new(current_user: user) }

  let(:ticket)  { create(:ticket, customer: create(:agent)) }
  let(:user)    { create(:agent, groups: [ticket.group]) }
  let(:payload) { { body: 'test' } }
  let(:article) { service.execute(article_data: payload, ticket: ticket) }

  describe '#execute' do
    it 'creates an article' do
      expect(article).to be_persisted
    end

    it 'creates an article even if contains wrong ticket id' do
      payload[:ticket_id] = 123_456

      expect(article).to be_persisted.and(have_attributes(ticket_id: ticket.id))
    end

    describe 'time accounting' do
      let(:time_accounting_enabled)  { true }
      let(:time_accounting_selector) { {} }

      before do
        Setting.set('time_accounting', time_accounting_enabled)
        Setting.set('time_accounting_selector', time_accounting_selector)

        payload[:time_unit] = 60
      end

      it 'adds time accounting if present' do
        expect(article.ticket_time_accounting).to be_present
      end

      context 'when time accounting is not enabled' do
        let(:time_accounting_enabled) { false }

        it 'does not save article and raises error' do
          expect { article }
            .to raise_error(%r{Time Accounting is not enabled})
        end
      end

      context 'when time accounting selector does not match' do
        let(:time_accounting_selector) do
          {
            'condition' => {
              'ticket.title' => {
                operator: 'contains',
                value:    'nonexistant title'
              }
            }
          }
        end

        it 'does not save article and raises error' do
          expect { article }
            .to raise_error(%r{Ticket does not match Time Accounting Selector})
        end
      end
    end

    describe 'to and cc fields processing' do
      it 'translates to and cc fields from arrays to strings' do
        payload.merge!({ to: %w[a b], cc: %w[b c] })

        expect(article).to have_attributes(to: 'a, b', cc: 'b, c')
      end

      it 'handles string and nil values' do
        payload.merge!({ to: 'a,b', cc: nil })

        expect(article).to have_attributes(to: 'a,b', cc: '')
      end
    end

    describe 'sender processing' do
      context 'when user is agent' do
        it 'agent is set to agent' do
          expect(article.sender.name).to eq 'Agent'
        end

        it 'preserves original value if given' do
          payload[:sender] = 'Customer'

          expect(article.sender.name).to eq 'Customer'
        end
      end

      context 'when user is customer' do
        let(:user)   { ticket.customer }
        let(:ticket) { create(:ticket, customer: create(:customer)) }

        it 'ensures sender is set to customer' do
          expect(article.sender.name).to eq 'Customer'
        end
      end

      # Agent-Customer is incorrectly detected as Agent in a group he has no access to
      # https://github.com/zammad/zammad/issues/4649
      context 'when user is agent-customer' do
        let(:user) { ticket.customer }

        it 'ensures sender is set to customer' do
          expect(article.sender.name).to eq 'Agent'
        end
      end
    end

    describe 'processing for customer' do
      context 'when user is customer' do
        let(:user)   { ticket.customer }
        let(:ticket) { create(:ticket, customer: create(:customer)) }

        it 'ensures internal is false' do
          payload[:internal] = true

          expect(article.internal).to be_falsey
        end

        it 'changes type from web to note' do
          payload[:type] = 'phone'

          expect(article.type.name).to eq('note')
        end
      end

      # Agent-Customer is incorrectly detected as Agent in a group he has no access to
      # https://github.com/zammad/zammad/issues/4649
      context 'when user is agent-customer' do
        let(:user) { ticket.customer }

        it 'ensures internal is false' do
          payload[:internal] = false

          expect(article.internal).to be_falsey
        end

        it 'changes type from web to note' do
          payload[:type] = 'phone'

          expect(article.type.name).to eq('phone')
        end
      end

      context 'when user is agent' do
        it 'allows internal to be true' do
          payload[:internal] = true

          expect(article.internal).to be_truthy
        end

        it 'applies no changes to type' do
          payload[:type] = 'phone'

          expect(article.type.name).to eq('phone')
        end
      end
    end

    describe 'transforming attachments' do
      it 'adds attachments with inlines' do
        payload[:content_type] = 'text/html'
        payload[:body] = 'some body <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA
  AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO
  9TXL0Y4OHwAAAABJRU5ErkJggg==" alt="Red dot" />'

        expect(article.attachments).to be_one
      end
    end
  end
end
