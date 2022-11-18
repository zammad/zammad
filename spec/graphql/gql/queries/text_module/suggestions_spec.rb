# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::TextModule::Suggestions, authenticated_as: :agent, type: :graphql do

  context 'when searching for text modules' do
    let(:groups)   { create_list(:group, 2) }
    let(:agent)    { create(:agent, groups: groups) }
    let(:ticket)   { create(:ticket, group: groups.first) }
    let(:customer) { create(:customer) }
    let!(:text_modules) do
      create_list(:text_module, 4).each_with_index do |tm, i|
        tm.name = "TextModuleTest#{i}"
        tm.keywords = "KeywordTextModuleTest#{i}"
        tm.content = '#{ticket.customer.fullname}-#{user.fullname}' # rubocop:disable Lint/InterpolationCheck
        tm.groups = if i <= 2
                      groups
                    elsif i == 3
                      [create(:group)]
                    else
                      []
                    end
        tm.save!
      end
    end
    let(:query) do
      <<~QUERY
        query textModuleSuggestions($query: String!, $limit: Int, $ticketId: ID, $customerId: ID)  {
          textModuleSuggestions(query: $query, limit: $limit) {
            name
            keywords
            content
            renderedContent(templateRenderContext: { ticketId: $ticketId, customerId: $customerId })
          }
        }
      QUERY
    end
    let(:variables)    { { query: query_string, limit: limit, ticketId: gql.id(ticket), customerId: gql.id(customer) } }
    let(:query_string) { 'TextModuleTest' }
    let(:limit)        { nil }

    before do
      gql.execute(query, variables: variables)
    end

    context 'without limit' do
      it 'finds all text modules with permission' do
        expect(gql.result.data.length).to eq(3)
      end
    end

    context 'with inactive text modules' do
      let(:limit) do
        text_modules.each do |tm|
          tm.active = false
          tm.save!
        end
        nil
      end

      it 'finds none' do
        expect(gql.result.data.length).to eq(0)
      end
    end

    context 'with limit' do
      let(:limit) { 1 }

      it 'respects the limit' do
        expect(gql.result.data.length).to eq(limit)
      end
    end

    context 'with exact search' do
      context 'with a ticket present' do
        let(:first_text_module_payload) do
          {
            'name'            => text_modules.first.name,
            'keywords'        => text_modules.first.keywords,
            'content'         => text_modules.first.content,
            'renderedContent' => "#{ticket.customer.fullname}-#{agent.fullname}",
          }
        end
        let(:query_string) { text_modules.first.name }

        it 'has data' do
          expect(gql.result.data).to eq([first_text_module_payload])
        end
      end

      context 'without a ticket, but with a customer present' do
        let(:variables) { { query: query_string, limit: limit, customerId: gql.id(customer) } }
        let(:first_text_module_payload) do
          {
            'name'            => text_modules.first.name,
            'keywords'        => text_modules.first.keywords,
            'content'         => text_modules.first.content,
            'renderedContent' => "#{customer.fullname}-#{agent.fullname}",
          }
        end
        let(:query_string) { text_modules.first.name }

        it 'has data' do
          expect(gql.result.data).to eq([first_text_module_payload])
        end
      end
    end

    context 'when sending an empty search string' do
      let(:query_string) { '   ' }
      let(:limit)        { 3 }

      it 'still returns text modules' do
        expect(gql.result.data.length).to eq(3)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
