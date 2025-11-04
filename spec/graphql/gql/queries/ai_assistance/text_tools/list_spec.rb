# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::AIAssistance::TextTools::List, type: :graphql do
  context 'when fetching AI text tools' do
    let(:agent)         { create(:agent) }
    let(:customer)      { create(:customer) }
    let(:group)         { create(:group) }
    let(:another_group) { create(:group) }

    let(:query) do
      <<~QUERY
        query aiAssistanceTextToolsList($groupId: ID, $ticketId: ID, $limit: Int) {
          aiAssistanceTextToolsList(groupId: $groupId, ticketId: $ticketId, limit: $limit) {
            id
            name
          }
        }
      QUERY
    end

    let(:variables) { {} }

    before do
      AI::TextTool.destroy_all

      text_tools if defined? text_tools

      gql.execute(query, variables: variables)
    end

    shared_examples 'returning empty list' do
      it 'returns empty list' do
        expect(gql.result.data).to eq([])
      end
    end

    shared_examples 'returning complete list' do
      it 'returns complete list' do
        expect(gql.result.data).to eq(text_tools.sort_by(&:name).map do |tool|
                                        {
                                          'id'   => gql.id(tool),
                                          'name' => tool.name,
                                        }
                                      end)
      end
    end

    context 'with an agent user', authenticated_as: :agent do

      context 'when no text tools exist' do
        it_behaves_like 'returning empty list'
      end

      context 'when text tools without groups exist' do
        let(:text_tools) do
          create_list(:ai_text_tool, 3).tap do |tools|
            tools.each_with_index do |tool, index|
              tool.update(name: "Test text tool #{index + 1}")
            end
          end
        end

        it_behaves_like 'returning complete list'
      end

      context 'when text tools with and without groups exist' do
        let(:text_tools) do
          tools = create_list(:ai_text_tool, 3).tap do |tools|
            tools.each_with_index do |tool, index|
              tool.update(name: "Test text tool #{index + 1}")
            end
          end

          tools[0].update(groups: [group])
          tools[1].update(groups: [another_group])

          tools
        end

        context 'when agent has access to the groups' do
          let(:agent) { create(:agent, groups: [group, another_group]) }

          it_behaves_like 'returning complete list'

          context 'when a group is passed' do
            let(:variables) { { groupId: gql.id(group) } }

            it 'returns filtered list' do
              expect(gql.result.data).to contain_exactly({
                                                           'id'   => gql.id(text_tools[0]),
                                                           'name' => text_tools[0].name,
                                                         },
                                                         {
                                                           'id'   => gql.id(text_tools[2]),
                                                           'name' => text_tools[2].name,
                                                         })
            end
          end
        end

        context 'when agent has no access to the groups' do
          it 'returns filtered list' do
            expect(gql.result.data).to contain_exactly({
                                                         'id'   => gql.id(text_tools[2]),
                                                         'name' => text_tools[2].name,
                                                       })
          end
        end
      end

      context 'when text tools just with groups exist' do
        let(:text_tools) do
          create_list(:ai_text_tool, 3, groups: [group, another_group]).tap do |tools|
            tools.each_with_index do |tool, index|
              tool.update(name: "Test text tool #{index + 1}")
            end
          end
        end

        context 'when agent has access to the groups' do
          let(:agent) { create(:agent, groups: [group, another_group]) }

          it_behaves_like 'returning complete list'

          context 'when a group is passed' do
            let(:variables) { { groupId: gql.id(group) } }

            it_behaves_like 'returning complete list'
          end
        end

        context 'when agent has no access to the groups' do
          it_behaves_like 'returning empty list'
        end
      end
    end

    context 'with a customer user', authenticated_as: :customer do
      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
