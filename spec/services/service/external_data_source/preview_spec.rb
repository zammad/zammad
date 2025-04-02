# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Copyright (C) 2013-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::ExternalDataSource::Preview do
  describe '#execute', db_adapter: :postgresql do
    context 'with ElasticSearch', searchindex: true do
      let(:data_option) do
        create(:object_manager_attribute_autocompletion_ajax_external_data_source, :elastic_search)
          .data_option
      end

      let(:searchterm) { SecureRandom.uuid }
      let(:user1)      { create(:agent, firstname: searchterm) }
      let(:user2)      { create(:agent, firstname: searchterm) }

      before do
        user1
        user2
        searchindex_model_reload([User])
      end

      it 'returns search results' do
        result = described_class.new.execute(data_option: data_option, render_context: {}, term: searchterm)

        expect(result).to include(
          success: true,
          data:    eq([
                        { value: user1.id.to_s, label: user1.email },
                        { value: user2.id.to_s, label: user2.email }
                      ])
        )
      end
    end

    context 'with mocked response' do
      let(:instance) { described_class.new }
      let(:json_response) do
        {
          'deadend' => 'yes',
          'results' => {
            'items' => [
              { 'data' => { 'id' => 1, 'name' => 'name 1' } },
              { 'data' => { 'id' => 2, 'name' => 'name 2' } },
              { 'data' => { 'id' => 3, 'name' => false } },
              { 'data' => { 'id' => 4, 'name' => true } },
            ]
          }
        }
      end
      let(:list_key)  { 'results.items' }
      let(:value_key) { 'data.id' }
      let(:label_key) { 'data.name' }

      let(:data_option) do
        create(:object_manager_attribute_autocompletion_ajax_external_data_source,
               list_key:  list_key,
               value_key: value_key,
               label_key: label_key)
          .data_option
      end

      before do
        allow_any_instance_of(ExternalDataSource)
          .to receive(:fetch_json)
          .and_return(json_response)
      end

      it 'returns correct data' do
        result = instance.execute(data_option: data_option, render_context: {}, term: 'term')

        expect(result).to include(
          success: true,
          data:    eq([
                        { value: 1, label: 'name 1' },
                        { value: 2, label: 'name 2' },
                        { value: 3, label: false },
                        { value: 4, label: true },
                      ])
        )
      end

      context 'when list parsing fails' do
        let(:list_key) { 'deadend' }

        it 'raises error' do
          result = instance.execute(data_option: data_option, render_context: {}, term: 'term')

          expect(result).to include(
            success:       false,
            error:         'Search result list key "deadend" is not an array.',
            response_body: json_response,
            parsed_items:  be_nil
          )
        end
      end

      context 'when item parsing fails' do
        let(:label_key) { 'nonexistant' }

        it 'raises error' do
          result = instance.execute(data_option: data_option, render_context: {}, term: 'term')

          expect(result).to include(
            success:       false,
            error:         'Search result label key "nonexistant" was not found.',
            response_body: json_response,
            parsed_items:  json_response.dig('results', 'items')
          )
        end
      end
    end
  end
end
