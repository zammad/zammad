# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::ExternalDataSource::Search do
  describe '#execute', db_adapter: :postgresql do
    context 'with ElasticSearch', searchindex: true do
      let(:attribute) do
        create(:object_manager_attribute_autocompletion_ajax_external_data_source, :elastic_search)
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
        json = described_class.new.execute(attribute: attribute, render_context: {}, term: searchterm)

        expect(json).to eq([
                             { value: user1.id.to_s, label: user1.email },
                             { value: user2.id.to_s, label: user2.email }
                           ])
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

      let(:attribute) do
        create(:object_manager_attribute_autocompletion_ajax_external_data_source,
               list_key:  list_key,
               value_key: value_key,
               label_key: label_key)
      end

      before do
        allow_any_instance_of(ExternalDataSource)
          .to receive(:fetch_json)
          .and_return(json_response)
      end

      it 'returns correct data' do
        json = instance.execute(attribute: attribute, render_context: {}, term: 'term')

        expect(json).to eq([
                             { value: 1, label: 'name 1' },
                             { value: 2, label: 'name 2' },
                             { value: 3, label: false },
                             { value: 4, label: true },
                           ])
      end

      context 'when parsing fails' do
        let(:list_key) { 'deadend' }

        it 'raises error' do
          expect { instance.execute(attribute: attribute, render_context: {}, term: 'term') }
            .to raise_error(Exceptions::UnprocessableEntity)
        end
      end
    end
  end
end
