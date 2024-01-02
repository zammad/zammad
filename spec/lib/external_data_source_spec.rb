# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ExternalDataSource do
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
        result = described_class.new(options: data_option, render_context: {}, term: searchterm).process

        expect(result).to eq([
                               { value: user1.id.to_s, label: user1.email },
                               { value: user2.id.to_s, label: user2.email }
                             ])
      end
    end

    describe 'handling configuration errors' do
      let(:data_option) do
        create(:object_manager_attribute_autocompletion_ajax_external_data_source, search_url: search_url)
          .data_option
      end

      context 'when search url is nil' do
        let(:search_url) { nil }

        it 'raises error' do
          instance = described_class.new(options: data_option, render_context: {}, term: 'term')
          expect { instance.process }
            .to raise_error(
              an_instance_of(ExternalDataSource::Errors::SearchUrlMissingError)
              .and(having_attributes(external_data_source: instance))
            )
        end
      end

      context 'when search url is not parsable URI' do
        let(:search_url) { 'loremipsum' }

        it 'raises error' do
          instance = described_class.new(options: data_option, render_context: {}, term: 'term')
          expect { instance.process }
            .to raise_error(
              an_instance_of(ExternalDataSource::Errors::SearchUrlInvalidError)
              .and(having_attributes(external_data_source: instance))
            )
        end
      end

      context 'when search url is bad URI' do
        let(:search_url) { 'http://host.com?#{search.t' }

        it 'raises error' do
          instance = described_class.new(options: data_option, render_context: {}, term: 'term')
          expect { instance.process }
            .to raise_error(
              an_instance_of(ExternalDataSource::Errors::SearchUrlInvalidError)
              .and(having_attributes(external_data_source: instance))
            )
        end
      end
    end

    describe 'handling of external data source' do
      let(:instance) { described_class.new }

      let(:search_url) { 'https://dummyjson.com' }
      let(:data_option) do
        create(:object_manager_attribute_autocompletion_ajax_external_data_source, search_url: search_url, list_key: '')
          .data_option
      end

      before do
        allow(UserAgent).to receive(:get).and_return(UserAgent::Result.new(success: true, data: []))
      end

      context 'when search URL contains placeholders' do
        let(:ticket)     { create(:ticket) }
        let(:search_url) { 'https://dummyjson.com/ticket/#{ticket.id}' } # rubocop:disable Lint/InterpolationCheck

        it 'replaces placeholders correctly' do
          described_class.new(options: data_option, render_context: { ticket: ticket }, term: 'term', limit: 1).process

          expect(UserAgent)
            .to have_received(:get)
            .with("https://dummyjson.com/ticket/#{ticket.id}", anything, anything)
        end
      end

      context 'when search term contains umlauts (#4980)' do
        let(:search_term) { 'bücher' }
        let(:search_url)  { 'https://dummyjson.com/products/search?q=#{search.term}' } # rubocop:disable Lint/InterpolationCheck

        it 'properly URL encodes search term' do
          described_class.new(options: data_option, render_context: {}, term: search_term, limit: 1).process

          expect(UserAgent)
            .to have_received(:get)
            .with("https://dummyjson.com/products/search?q=#{ERB::Util.url_encode(search_term)}", anything, anything)
        end
      end

      context 'when http basic username and password present' do
        before do
          data_option[:http_basic_auth_username] = 'test_username'
          data_option[:http_basic_auth_password] = 'test_password'
        end

        it 'sets username and password' do
          described_class.new(options: data_option, render_context: {}, term: 'term', limit: 1).process

          expect(UserAgent)
            .to have_received(:get)
            .with(anything, anything, include(user: 'test_username', password: 'test_password'))
        end
      end

      context 'when bearer token present' do
        before do
          data_option[:bearer_token_auth] = 'test_bearer_token'
        end

        it 'sets authorization token' do
          described_class.new(options: data_option, render_context: {}, term: 'term', limit: 1).process

          expect(UserAgent)
            .to have_received(:get)
            .with(anything, anything, include(bearer_token: 'test_bearer_token'))
        end
      end

      context 'when SSL verification flag present' do
        before do
          data_option[:verify_ssl] = false
        end

        it 'sets SSL verification flag' do
          described_class.new(options: data_option, render_context: {}, term: 'term', limit: 1).process

          expect(UserAgent)
            .to have_received(:get)
            .with(anything, anything, include(verify_ssl: false))
        end
      end
    end

    context 'with mocked response' do
      let(:instance) { described_class.new }

      let(:data_option) do
        create(:object_manager_attribute_autocompletion_ajax_external_data_source,
               list_key:  list_key,
               value_key: value_key,
               label_key: label_key)
          .data_option
      end

      before do
        allow_any_instance_of(described_class)
          .to receive(:fetch_json)
          .and_return(json_response)
      end

      context 'with simple structure' do
        let(:json_response) do
          {
            'items' => [
              { 'id' => 1, 'name' => 'name 1' },
              { 'id' => 2, 'name' => 'name 2' },
            ]
          }
        end

        let(:list_key)  { 'items' }
        let(:value_key) { 'id' }
        let(:label_key) { 'name' }

        it 'returns correct data' do
          result = described_class.new(options: data_option, render_context: {}, term: 'term').process

          expect(result).to eq([
                                 { value: 1, label: 'name 1' },
                                 { value: 2, label: 'name 2' },
                               ])
        end

        it 'returns limited set' do
          result = described_class.new(options: data_option, render_context: {}, term: 'term', limit: 1).process

          expect(result).to eq([
                                 { value: 1, label: 'name 1' },
                               ])
        end
      end

      context 'with minimal structure' do
        let(:json_response) do
          %w[foo bar]
        end

        let(:list_key)  { '' }
        let(:value_key) { '' }
        let(:label_key) { '' }

        it 'returns correct data' do
          result = described_class.new(options: data_option, render_context: {}, term: 'term').process

          expect(result).to eq([
                                 { value: 'foo', label: 'foo' },
                                 { value: 'bar', label: 'bar' },
                               ])
        end
      end

      context 'with complex structure' do
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

        it 'returns correct data' do
          result = described_class.new(options: data_option, render_context: {}, term: 'term').process

          expect(result).to eq([
                                 { value: 1, label: 'name 1' },
                                 { value: 2, label: 'name 2' },
                                 { value: 3, label: false },
                                 { value: 4, label: true },
                               ])
        end

        context 'when list points to string' do
          let(:list_key) { 'deadend' }

          it 'raises error' do
            instance = described_class.new(options: data_option, render_context: {}, term: 'term')

            expect { instance.process }
              .to raise_error(
                an_instance_of(ExternalDataSource::Errors::ListNotArrayParsingError)
                .and(having_attributes(
                       external_data_source: having_attributes(
                         json:         json_response,
                         parsed_items: be_nil
                       ),
                       message:              'Search result list key "deadend" is not an array.'
                     ))
              )
          end
        end

        context 'when list points to hash' do
          let(:list_key) { 'results' }

          it 'raises error' do
            instance = described_class.new(options: data_option, render_context: {}, term: 'term')

            expect { instance.process }
              .to raise_error(
                an_instance_of(ExternalDataSource::Errors::ListNotArrayParsingError)
                .and(having_attributes(
                       external_data_source: having_attributes(
                         json:         json_response,
                         parsed_items: be_nil
                       ),
                       message:              'Search result list key "results" is not an array.'
                     ))
              )
          end
        end

        context 'when list points to array member' do
          let(:list_key) { 'results.items.data' }

          it 'raises error' do
            instance = described_class.new(options: data_option, render_context: {}, term: 'term')

            expect { instance.process }
              .to raise_error(
                an_instance_of(ExternalDataSource::Errors::ListPathParsingError)
                .and(having_attributes(
                       external_data_source: having_attributes(
                         json:         json_response,
                         parsed_items: be_nil
                       ),
                       message:              'Search result list key "results.items.data" was not found.'
                     ))
              )
          end
        end

        context 'when list points to non existant key' do
          let(:list_key) { 'nonexistant' }

          it 'raises error' do
            instance = described_class.new(options: data_option, render_context: {}, term: 'term')

            expect { instance.process }
              .to raise_error(
                an_instance_of(ExternalDataSource::Errors::ListPathParsingError)
                .and(having_attributes(
                       external_data_source: having_attributes(
                         json:         json_response,
                         parsed_items: be_nil
                       ),
                       message:              'Search result list key "nonexistant" was not found.'
                     ))
              )
          end
        end

        context 'when list fails to pick root element' do
          let(:list_key) { '' }

          it 'raises error' do
            instance = described_class.new(options: data_option, render_context: {}, term: 'term')

            expect { instance.process }
              .to raise_error(
                an_instance_of(ExternalDataSource::Errors::ListNotArrayParsingError)
                .and(having_attributes(
                       external_data_source: having_attributes(
                         json:         json_response,
                         parsed_items: be_nil
                       ),
                       message:              'Search result list is not an array. Please provide search result list key.'
                     ))
              )
          end
        end

        context 'when value points to hash' do
          let(:value_key) { 'data' }

          it 'raises error' do
            instance = described_class.new(options: data_option, render_context: {}, term: 'term')

            expect { instance.process }
              .to raise_error(
                an_instance_of(ExternalDataSource::Errors::ItemValueInvalidTypeParsingError)
                .and(having_attributes(
                       external_data_source: having_attributes(
                         json:         json_response,
                         parsed_items: json_response.dig('results', 'items')
                       ),
                       message:              'Search result value key "data" is not a string, number or boolean.'
                     ))
              )
          end
        end

        context 'when value points to non existant key' do
          let(:value_key) { 'nonexistant' }

          it 'raises error' do
            instance = described_class.new(options: data_option, render_context: {}, term: 'term')

            expect { instance.process }
              .to raise_error(
                an_instance_of(ExternalDataSource::Errors::ItemValuePathParsingError)
                .and(having_attributes(
                       external_data_source: having_attributes(
                         json:         json_response,
                         parsed_items: json_response.dig('results', 'items')
                       ),
                       message:              'Search result value key "nonexistant" was not found.'
                     ))
              )
          end
        end

        context 'when value fails to pick root element' do
          let(:value_key) { '' }

          it 'raises error' do
            instance = described_class.new(options: data_option, render_context: {}, term: 'term')

            expect { instance.process }
              .to raise_error(
                an_instance_of(ExternalDataSource::Errors::ItemValueInvalidTypeParsingError)
                .and(having_attributes(
                       external_data_source: having_attributes(
                         json:         json_response,
                         parsed_items: json_response.dig('results', 'items')
                       ),
                       message:              'Search result value is not a string, a number or a boolean. Please provide search result value key.'
                     ))
              )
          end
        end

        context 'when label points to hash' do
          let(:label_key) { 'data' }

          it 'raises error' do
            instance = described_class.new(options: data_option, render_context: {}, term: 'term')

            expect { instance.process }
              .to raise_error(
                an_instance_of(ExternalDataSource::Errors::ItemLabelInvalidTypeParsingError)
                .and(having_attributes(
                       external_data_source: having_attributes(
                         json:         json_response,
                         parsed_items: json_response.dig('results', 'items')
                       ),
                       message:              'Search result label key "data" is not a string, number or boolean.'
                     ))
              )
          end
        end

        context 'when label points to non existant key' do
          let(:label_key) { 'nonexistant' }

          it 'raises error' do
            instance = described_class.new(options: data_option, render_context: {}, term: 'term')

            expect { instance.process }
              .to raise_error(
                an_instance_of(ExternalDataSource::Errors::ItemLabelPathParsingError)
                .and(having_attributes(
                       external_data_source: having_attributes(
                         json:         json_response,
                         parsed_items: json_response.dig('results', 'items')
                       ),
                       message:              'Search result label key "nonexistant" was not found.'
                     ))
              )
          end
        end

        context 'when label fails to pick root element' do
          let(:label_key) { '' }

          it 'raises error' do
            instance = described_class.new(options: data_option, render_context: {}, term: 'term')

            expect { instance.process }
              .to raise_error(
                an_instance_of(ExternalDataSource::Errors::ItemLabelInvalidTypeParsingError)
                .and(having_attributes(
                       external_data_source: having_attributes(
                         json:         json_response,
                         parsed_items: json_response.dig('results', 'items')
                       ),
                       message:              'Search result label is not a string, a number or a boolean. Please provide search result label key.'
                     ))
              )
          end
        end
      end
    end
  end
end
