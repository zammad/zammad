# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Create, :aggregate_failures, type: :graphql do
  let(:query) do
    <<~QUERY
      mutation ticketCreate($input: TicketCreateInput!) {
        ticketCreate(input: $input) {
          ticket {
            id
            title
            group {
              name
            }
            priority {
              name
            }
            customer {
              fullname
            }
            owner {
              fullname
            }
            objectAttributeValues {
              attribute {
                name
              }
              value
            }
            tags
          }
          errors {
            message
            field
          }
        }
      }
    QUERY
  end
  let(:agent)    { create(:agent, groups: [ Group.find_by(name: 'Users')]) }
  let(:customer) { create(:customer) }
  let(:user)     { agent }
  let(:group)    { agent.groups.first }
  let(:priority) { Ticket::Priority.last }

  let(:article_payload) { nil }

  let(:input_base_payload) do
    {
      title:      'Ticket Create Mutation Test',
      groupId:    gql.id(group),
      priorityId: gql.id(priority),
      customerId: gql.id(customer),
      ownerId:    gql.id(agent),
      tags:       %w[foo bar],
      article:    article_payload
      # pending_time: 10.minutes.from_now,
      # type: ...
    }
  end

  let(:input_payload) { input_base_payload }
  let(:variables)     { { input: input_payload } }

  let(:expected_base_response) do
    {
      'id'                    => gql.id(Ticket.last),
      'title'                 => 'Ticket Create Mutation Test',
      'owner'                 => { 'fullname' => agent.fullname },
      'group'                 => { 'name' => agent.groups.first.name },
      'customer'              => { 'fullname' => customer.fullname },
      'priority'              => { 'name' => Ticket::Priority.last.name },
      'tags'                  => %w[foo bar],
      'objectAttributeValues' => [],
    }
  end

  let(:expected_response) do
    expected_base_response
  end

  def it_creates_ticket(articles: 0, stores: 0)
    expect { gql.execute(query, variables: variables) }
      .to change(Ticket, :count).by(1)
      .and change(Ticket::Article, :count).by(articles)
      .and change(Store, :count).by(stores)
  end

  def it_fails_to_create_ticket
    expect { gql.execute(query, variables: variables) }
      .not_to change(Ticket, :count)
  end

  context 'when creating a new ticket' do

    context 'with an agent', authenticated_as: :agent do

      it 'creates Ticket record' do
        it_creates_ticket
        expect(gql.result.data['ticket']).to eq(expected_response)
      end

      context 'without title' do
        let(:input_payload) { input_base_payload.tap { |h| h[:title] = '   ' } }

        it 'fails validation' do
          it_fails_to_create_ticket
          expect(gql.result.error_message).to include('Variable $input of type TicketCreateInput! was provided invalid value for title')
        end
      end

      context 'with custom object_attribute', db_strategy: :reset do
        let(:object_attribute) do
          screens = { create: { 'admin.organization': { shown: true, required: false } } }
          create(:object_manager_attribute_text, object_name: 'Ticket', screens: screens).tap do |_oa|
            ObjectManager::Attribute.migration_execute
          end
        end
        let(:input_payload) do
          input_base_payload.merge(
            {
              objectAttributeValues: [ { name: object_attribute.name, value: 'object_attribute_value' } ]
            }
          )
        end
        let(:expected_response) do
          expected_base_response.merge(
            {
              'objectAttributeValues' => [{ 'attribute' => { 'name'=>object_attribute.name }, 'value' => 'object_attribute_value' }]
            }
          )
        end

        it 'creates the ticket' do
          it_creates_ticket
          expect(gql.result.data['ticket']).to eq(expected_response)
        end
      end

      context 'with no permission to the group' do
        let(:group) { create(:group) }

        it 'raises an error', :aggregate_failures do
          it_fails_to_create_ticket
          expect(gql.result.error_type).to eq(GraphQL::ExecutionError)
          expect(gql.result.error_message).to eq('Access forbidden by Gql::Types::GroupType')
        end
      end

      context 'with article' do
        before do
          Group.find(agent.groups.first.id).update(email_address: create(:email_address))
        end

        context 'with inline attachments' do
          let(:body) do
            <<~BODY
              This is a test article with inline attachments.

              <img tabindex="0" style="width: 421px; max-width: 100%;" src="data:image/png;base64,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" />
            BODY
          end

          let(:article_payload) do
            {
              body:        body,
              contentType: 'text/html',
            }
          end

          it 'creates a new ticket + a new article with inline attachments' do
            it_creates_ticket(articles: 1, stores: 1)
            expect(Store.last.filename).to eq('image1.png')
          end
        end

        context 'with attachments' do
          let(:article_payload) do
            form_id = 12_345

            file_name    = 'file1.txt'
            file_type    = 'text/plain'
            file_content = Base64.strict_encode64('file1')

            UploadCache.new(form_id).tap do |cache|
              cache.add(
                data:          file_content,
                filename:      file_name,
                preferences:   { 'Content-Type' => file_type },
                created_by_id: agent.id
              )
            end

            {
              body:        'dummy',
              contentType: 'text/html',
              attachments: {
                formId: form_id,
                files:  [
                  {
                    name:    file_name,
                    type:    file_type,
                    content: file_content,
                  },
                ],
              },
            }
          end

          it 'creates a new ticket + a new article with attachments' do
            it_creates_ticket(articles: 1, stores: 1)
            expect(Store.last.filename).to eq('file1.txt')
          end
        end

        context 'with inline attachments + attachments' do
          let(:body) do
            <<~BODY
              This is a test article with inline attachments.

              <img tabindex="0" style="width: 421px; max-width: 100%;" src="data:image/png;base64,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" />
            BODY
          end

          let(:article_payload) do
            form_id = 12_345

            file_name    = 'file1.txt'
            file_type    = 'text/plain'
            file_content = Base64.strict_encode64('file1')

            UploadCache.new(form_id).tap do |cache|
              cache.add(
                data:          file_content,
                filename:      file_name,
                preferences:   { 'Content-Type' => file_type },
                created_by_id: agent.id
              )
            end

            {
              body:        body,
              contentType: 'text/html',
              attachments: {
                formId: form_id,
                files:  [
                  {
                    name:    file_name,
                    type:    file_type,
                    content: file_content,
                  },
                ],
              },
            }
          end

          it 'creates a new ticket + a new article with inline attachments + attachments' do
            it_creates_ticket(articles: 1, stores: 2)
            expect(Store.last.filename).to eq('image1.png')
          end
        end

        context 'with a specific sender' do
          let(:article_payload) do
            {
              body:   'dummy',
              sender: 'Agent',
            }
          end

          it 'creates a new ticket + a new article with a specific sender' do
            it_creates_ticket(articles: 1)
            expect(Ticket.last.articles.last.sender.name).to eq('Agent')
          end

          it 'sets correct "to" and "from" values', :aggregate_failures do
            it_creates_ticket(articles: 1)
            expect(Ticket.last.articles.last.from).to eq(agent.fullname)
            expect(Ticket.last.articles.last.to).to eq("#{customer.fullname} <#{customer.email}>")
          end
        end

        context 'with no type' do
          let(:article_payload) do
            {
              body: 'dummy',
            }
          end

          it 'creates a new ticket + a new article, but falls back to type "note"' do
            it_creates_ticket(articles: 1)
            expect(Ticket.last.articles.last.type.name).to eq('note')
          end
        end

        context 'with a specific type' do
          let(:article_payload) do
            {
              body: 'dummy',
              type: Ticket::Article::Type.first.name,
            }
          end

          it 'creates a new ticket + a new article with a specific type' do
            it_creates_ticket(articles: 1)
            expect(Ticket.last.articles.last.type.name).to eq(Ticket::Article::Type.first.name)
          end
        end
      end

      context 'with to: and cc: being string values' do
        let(:article_payload) do
          {
            body: 'dummy',
            to:   'to@example.com',
            cc:   'cc@example.com',
          }
        end

        it 'creates a new ticket + a new article and sets correct "to" and "cc" values', :aggregate_failures do
          it_creates_ticket(articles: 1)
          expect(Ticket.last.articles.last).to have_attributes(to: 'to@example.com', cc: 'cc@example.com')
        end
      end

      context 'with to: and cc: containing array values' do
        let(:article_payload) do
          {
            body: 'dummy',
            to:   ['to@example.com', 'to2@example.com'],
            cc:   ['cc@example.com', 'cc2@example.com'],
          }
        end

        it 'creates a new ticket + a new article and sets correct "to" and "cc" values', :aggregate_failures do
          it_creates_ticket(articles: 1)
          expect(Ticket.last.articles.last).to have_attributes(to: 'to@example.com, to2@example.com', cc: 'cc@example.com, cc2@example.com')
        end
      end
    end

    context 'with a customer', authenticated_as: :customer do
      let(:input_payload) { input_base_payload.tap { |h| h.delete(:customerId) } }

      let(:expected_response) do
        expected_base_response.merge(
          {
            'owner'    => { 'fullname' => nil },
            'priority' => { 'name' => Ticket::Priority.where(default_create: true).first.name },
            'tags'     => nil
          }
        )
      end

      it 'creates the ticket with filtered values' do
        it_creates_ticket
        expect(gql.result.data['ticket']).to eq(expected_response)
      end

      context 'when sending a different customerId' do
        let(:input_payload) { input_base_payload.tap { |h| h[:customerId] = create(:customer).id } }

        it 'overrides the customerId' do
          it_creates_ticket
          expect(gql.result.data['ticket']).to eq(expected_response)
        end
      end

      context 'with article' do
        context 'with a forbidden sender' do
          let(:article_payload) do
            {
              body:   'dummy',
              sender: 'Agent',
            }
          end

          it 'creates a new ticket + a new article, but falls back to "Customer" as sender' do
            it_creates_ticket(articles: 1)
            expect(Ticket.last.articles.last.sender.name).to eq('Customer')
          end
        end

        context 'with type "web"' do
          let(:article_payload) do
            {
              body: 'dummy',
              type: 'web',
            }
          end

          it 'creates a new ticket + a new article, but falls back to "note" as type' do
            it_creates_ticket(articles: 1)
            expect(Ticket.last.articles.last.type.name).to eq('note')
          end

          it 'sets correct "to" and "from" values', :aggregate_failures do
            it_creates_ticket(articles: 1)
            expect(Ticket.last.articles.last.to).to eq(Ticket.last.group.name)
            expect(Ticket.last.articles.last.from).to eq(customer.fullname)
          end
        end

        context 'with an article flagged as internal' do
          let(:article_payload) do
            {
              body:     'dummy',
              internal: true,
            }
          end

          it 'creates a new ticket + a new article, but flags it as not internal' do
            it_creates_ticket(articles: 1)
            expect(Ticket.last.articles.last.internal).to be(false)
          end
        end
      end
    end
  end
end
