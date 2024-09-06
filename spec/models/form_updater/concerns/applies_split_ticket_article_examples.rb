# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'FormUpdater::AppliesSplitTicketArticle' do
  context 'when applying a splitting ticket article' do
    let(:object_name) { 'ticket' }
    let(:meta)        { { initial: true, form_id: SecureRandom.uuid, additional_data: } }

    context 'without a ticket article to split' do
      let(:additional_data) { {} }

      it 'skips the action and does not set any values' do
        expect(resolved_result.resolve[:fields]).to be_none { |_key, value| value.key? 'value' }
      end
    end

    context 'with a ticket article to split' do
      let(:customer)       { create(:customer) }
      let(:source_ticket)  { create(:ticket, group:, customer:) }
      let(:source_article) { create(:ticket_article, ticket: source_ticket) }

      let(:additional_data) { { 'splitTicketArticleId' => source_article.to_global_id.to_s } }

      it 'sets link ticket id' do
        expect(resolved_result.resolve).to include(fields: include('link_ticket_id' => include(value: source_ticket.id)))
      end

      it 'sets ticket atributes' do
        expect(resolved_result.resolve).to include(fields: include(
          'group_id'    => include(value: source_ticket.group_id),
          'customer_id' => include(value: source_ticket.customer_id),
          'state_id'    => include(value: source_ticket.state_id),
          'body'        => include(value: source_article.body),
        ))
      end

      context 'when article has no subject' do
        before { source_article.update! subject: '' }

        it 'sets source ticket title' do
          expect(resolved_result.resolve[:fields]).to include(
            'title' => include(value: source_ticket.title),
          )
        end
      end

      context 'when article has a subject' do
        before { source_article.update! subject: 'test subject' }

        it 'sets article subject as ticket title' do
          expect(resolved_result.resolve[:fields]).to include(
            'title' => include(value: source_article.subject),
          )
        end
      end

      context 'when ticket has an owner' do
        before { source_ticket.update! owner: create(:agent) }

        it 'does not set ticket owner' do
          expect(resolved_result.resolve[:fields]).not_to include(
            'owner_id' => include(value: be_present),
          )
        end
      end

      context 'when ticket customer and article author are different' do
        let(:other_customer) { create(:customer) }

        before do
          source_article.update! from: other_customer.email, origin_by: other_customer, created_by: other_customer
        end

        it 'sets ticket customer as customer' do
          expect(resolved_result.resolve[:fields]).to include(
            'customer_id' => include(value: source_ticket.customer_id),
          )
        end
      end

      context 'when article has attachments' do
        let(:source_article)       { create(:ticket_article, :with_attachment, ticket: source_ticket) }
        let(:cloned_attachment_id) { source_article.attachments.pick(:id).next }

        it 'sets copied non-inline attachments' do
          expect(resolved_result.resolve[:fields])
            .to include(
              'attachments' => include(value: include(
                include(
                  name: 'hello_world.txt',
                  id:   cloned_attachment_id
                )
              )),
            )
        end

        context 'when attachment is inline' do
          let(:attachment) { source_article.attachments.first }
          let(:cid)        { 'image_cid' }

          before do
            attachment.preferences['Content-ID'] = cid
            attachment.save!

            source_article.update! body: "<img src='cid:#{cid}'>", content_type: 'text/html'
          end

          it 'sets body with copied inline attachments' do
            expect(resolved_result.resolve[:fields])
              .to include(
                'body' => include(value: "<img src=\"/api/v1/attachments/#{cloned_attachment_id}\" cid=\"image_cid\">")
              )
          end
        end
      end

      context 'when given invalid article id' do
        let(:additional_data) { { 'splitTicketArticleId' => 'non-existant' } }

        it 'raises an error' do
          expect { resolved_result.resolve[:fields] }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

  end
end
