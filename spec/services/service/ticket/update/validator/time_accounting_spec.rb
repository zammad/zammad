# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Update::Validator::TimeAccounting do
  subject(:validator) { described_class.new(user: user, ticket: ticket, ticket_data: ticket_data, article_data: article_data) }

  let(:user)          { create(:agent, groups: [group]) }
  let(:ticket)        { create(:ticket) }
  let(:group)         { ticket.group }
  let(:new_title)     { Faker::Lorem.unique.word }
  let(:ticket_data)   { { title: new_title, state: Ticket::State.find_by(name: 'new') } }
  let(:article_data)  { nil }

  shared_examples 'not raising an error' do
    it 'does not raise an error' do
      expect { validator.valid! }.not_to raise_error
    end
  end

  shared_examples 'raising an error' do
    it 'raises an error' do
      expect { validator.valid! }.to raise_error(Service::Ticket::Update::Validator::TimeAccounting::Error, 'The ticket time accounting condition is met.')
    end
  end

  describe '#valid!' do
    it_behaves_like 'not raising an error'

    context 'when time accounting is enabled' do
      before do
        Setting.set('time_accounting', true)
      end

      context 'when ticket time accounting condition is met' do
        let(:article_type) { Ticket::Article::Type.find_by(name: 'note') }
        let(:article_internal) { true }
        let(:article_sender)   { Ticket::Article::Sender.find_by(name: 'Agent') }

        before do
          Setting.set(
            'time_accounting_selector',
            {
              'condition' => {
                'ticket.state_id'   => { 'operator' => 'is', 'value' => [ Ticket::State.find_by(name: 'new').id.to_s ] },
                'article.body'      => { 'operator' => 'matches regex', 'value' => 'lipsum' },
                'article.type_id'   => { 'operator' => 'is', 'value' => [article_type.id] },
                'article.internal'  => { 'operator' => 'is', 'value' => [article_internal] },
                'article.sender_id' => { 'operator' => 'is', 'value' => [article_sender.id] },
              }
            }
          )
        end

        it_behaves_like 'not raising an error'

        context 'when article is present' do
          let(:article_data) { { body: 'lipsum', type: article_type, internal: article_internal, sender: article_sender } }

          it_behaves_like 'raising an error'
        end

        context 'when article is present with time accounting data' do
          let(:article_data) { { body: 'lipsum', time_unit: 123 } }

          it_behaves_like 'not raising an error'
        end

        context 'when article is present with time accounting data set to zero' do
          let(:article_data) { { body: 'lipsum', time_unit: 0 } }

          it_behaves_like 'not raising an error'
        end
      end

      context 'when ticket time accounting condition is not met' do
        before do
          Setting.set('time_accounting_selector', { 'condition' => { 'ticket.state_id' => { 'operator' => 'is', 'value' => [ Ticket::State.find_by(name: 'open').id.to_s ] } } })
        end

        it_behaves_like 'not raising an error'
      end
    end
  end
end
