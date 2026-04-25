# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Update, current_user_id: -> { user.id } do
  subject(:service_result) { described_class.with_current_user(user).execute(ticket:, ticket_data:, macro:) }

  let(:user)        { create(:agent, groups: [group]) }
  let(:ticket)      { create(:ticket) }
  let(:group)       { ticket.group }
  let(:new_title)   { Faker::Lorem.word }
  let(:new_body)    { Faker::Lorem.sentence }
  let(:macro)       { nil }
  let(:ticket_data) { { title: new_title, time_unit: 2 } }

  let(:ticket_data_with_article) do
    ticket_data.merge(article: { body: new_body })
  end

  describe '#execute' do
    it 'updates a ticket with given metadata' do
      service_result

      expect(ticket)
        .to have_attributes(
          title: new_title,
        )
    end

    context 'when article is present' do
      let(:ticket_data) { { title: new_title, time_unit: 2, article: { body: new_body } } }

      it 'adds article' do
        service_result

        expect(Ticket.last.articles.last)
          .to have_attributes(
            body: new_body,
          )
      end

      it 'adds article accounted time to ticket' do
        expect(service_result.time_unit).to eq(2)
      end
    end

    context 'when macro is given' do
      let(:macro) { create(:macro, perform: { 'ticket.title' => { 'value' => new_title } }) }

      it 'updates ticket with given macro' do
        service_result

        expect(ticket)
          .to have_attributes(
            title: new_title,
          )
      end

      context 'when macro adds an article note' do
        let(:macro) do
          create(:macro, perform: {
                   'article.note' => { 'body' => 'note body', 'internal' => 'true', 'subject' => 'test' }
                 })
        end
        let(:ticket_data) { { title: new_title, time_unit: 2, article: { body: new_body } } }

        it 'adds article note via macro' do
          service_result

          expect(ticket.articles.reload)
            .to contain_exactly(
              have_attributes(body: new_body),
              have_attributes(body: 'note body'),
            )
        end
      end
    end

    describe 'shared draft handling' do
      let(:shared_draft) { create(:ticket_shared_draft_zoom, ticket:) }

      before { ticket_data[:shared_draft] = shared_draft }

      it 'destroys given shared draft' do
        service_result

        expect(Ticket::SharedDraftZoom).not_to exist(shared_draft.id)
      end

      it 'raises error if shared draft group does not belong to the ticket' do
        shared_draft.update! ticket: create(:ticket)

        expect { service_result }
          .to raise_error(Exceptions::UnprocessableContent)
      end
    end
  end
end
