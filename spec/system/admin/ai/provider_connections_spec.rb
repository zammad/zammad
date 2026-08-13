# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'AI > Provider Connections', type: :system do
  context 'when ajax pagination' do
    include_examples 'pagination', model: :ai_provider_connection, klass: AI::ProviderConnection, path: 'ai/providers'
  end

  context 'with connections', authenticated_as: :admin do
    let(:admin)       { create(:admin) }
    let(:self_hosted) { false }

    # What the providers of these examples answer their model listing request with: OpenAI reports
    # its models under 'data', Ollama under 'models'.
    let(:model_list) do
      {
        'data'   => [{ 'id' => 'gpt-4.1' }, { 'id' => 'text-embedding-3-small' }],
        'models' => [{ 'model' => 'mistral-small3.2' }, { 'model' => 'bge-m3' }],
      }
    end

    before do
      Setting.set('system_online_service', !self_hosted)

      result = UserAgent::Result.new(
        success: true,
        code:    200,
        data:    model_list,
      )

      allow(UserAgent).to receive_messages(get: result, post: result)

      visit '/#ai/providers'
    end

    describe 'creating a connection' do
      it 'creates a connection via the wizard and marks it as default' do
        click '[data-type=new]'

        in_modal disappears: true do
          find('select[name=provider]').select('OpenAI')

          # The name is deliberately not pre-filled from the provider, it is up to the admin.
          expect(page).to have_field('Token').and(have_field('name', with: ''))

          fill_in 'name',  with: 'openai'
          fill_in 'Token', with: 'test-token'

          click_on 'Next'
        end

        in_modal disappears: true do
          # Only the models the provider serves, and only those that fit the field: the embedding
          # model is no candidate to run the connection on. Picking nothing has a consequence, so
          # the empty option names the model that answers for it.
          expect(page)
            .to have_select('config.model', options: ['Default (gpt-4.1)', 'gpt-4.1'])
            .and(have_select('config.ocr_model', options: ['Default (gpt-4.1)', 'gpt-4.1']))
            .and(have_select('config.embedding_model', options: ['Default (text-embedding-3-small)', 'text-embedding-3-small']))

          # A new connection starts on the default rather than on a model it was signed up for -
          # sized like a picked one, because that is the model it will embed with.
          expect(page)
            .to have_select('config.model', selected: 'Default (gpt-4.1)')
            .and(have_select('config.embedding_model', selected: 'Default (text-embedding-3-small)'))
            .and(have_field('Embedding dimensions', with: AI::Provider::EMBEDDING_SIZES['text-embedding-3-small']))

          # The step before this one is what the footer offers to go back to, not the cancel of a
          # single step dialog.
          expect(page).to have_link('Back').and(have_no_link('Cancel & Go Back'))

          find('select[name="config.model"]').select('gpt-4.1')

          # Sizing the picked model needs no further request: the listing carries both values.
          find('select[name="config.embedding_model"]').select('text-embedding-3-small')

          expect(page)
            .to have_field('Embedding dimensions', with: AI::Provider::EMBEDDING_SIZES['text-embedding-3-small'])
            .and(have_field('Context window size', with: AI::Provider::EMBEDDING_INPUT_LIMITS['text-embedding-3-small']))

          click_on 'Submit'
        end

        within :active_content do
          expect(page).to have_text('openai')

          # The first connection automatically becomes the default for every mode.
          expect(find('tr', text: 'openai')).to have_text('Default')
        end

        connection = AI::ProviderConnection.find_by(name: 'openai')

        expect(connection).to have_attributes(provider: 'open_ai', default_chat: true)

        # The sizes persist as the numbers their consumers expect, not as the strings a form sends.
        expect(connection.config).to include(
          'model'                 => 'gpt-4.1',
          'embedding_model'       => 'text-embedding-3-small',
          'embedding_size'        => AI::Provider::EMBEDDING_SIZES['text-embedding-3-small'],
          'embedding_input_limit' => AI::Provider::EMBEDDING_INPUT_LIMITS['text-embedding-3-small'],
        )
      end

      # A provider that offers no model for a field leaves the admin to name it, rather than a
      # dropdown with nothing in it.
      context 'when the provider lists no models' do
        let(:model_list) { { 'data' => [], 'models' => [] } }

        it 'falls back to a mandatory text field that says why' do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('OpenAI')
            fill_in 'name',  with: 'openai'
            fill_in 'Token', with: 'test-token'

            click_on 'Next'
          end

          in_modal disappears: false do
            # By name: a required field carries an asterisk, so its label no longer matches 'Model'
            # exactly and the embedding and OCR fields make it ambiguous.
            expect(page)
              .to have_no_select('config.model')
              .and(have_field('config.model', with: ''))
              .and(have_text('The provider offered no models to choose from, so it has to be entered manually.'))

            # An endpoint that listed nothing was seen to serve nothing - its own defaults included.
            # So neither field arrives filled, and nothing describing an embedding model is asked
            # for either.
            expect(page)
              .to have_field('Embedding Model', with: '')
              .and(have_no_field('Embedding dimensions'))
              .and(have_no_field('Context window size'))

            # Nothing else names the model the connection runs on, so the step insists on it.
            click_on 'Submit'

            expect(page).to have_css('.has-error [name="config.model"]')
          end
        end
      end

      # The empty option claims what an empty field falls back to, whose ground truth is the
      # adapter (AI::Provider.default_model, AI::ProviderConnection#seed_embedding_default) - so
      # both labels come from the listing response. The AIProviders registry the dialog is built
      # from keeps no copy of them, which is what drifted from the adapter once already.
      context 'when the adapter defaults are other models than the registry knew' do
        let(:model_list) { { 'data' => [{ 'id' => 'adapter-model' }, { 'id' => 'adapter-embed' }] } }

        before do
          allow(AI::Provider::OpenAI).to receive_messages(default_model: 'adapter-model', recommended_embedding_model: 'adapter-embed')
        end

        it 'labels the empty options with the adapter defaults', :aggregate_failures do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('OpenAI')
            fill_in 'name',  with: 'openai'
            fill_in 'Token', with: 'test-token'

            click_on 'Next'
          end

          in_modal disappears: false do
            expect(page).to have_select('config.model', options: ['Default (adapter-model)', 'adapter-model'])
            expect(page).to have_select('config.embedding_model', options: ['Default (adapter-embed)', 'adapter-embed'])

            # The OCR model follows whichever model the connection ends up on, down to the one the
            # adapter falls back to where the model field names none either.
            expect(page).to have_select('config.ocr_model', options: ['Default (adapter-model)', 'adapter-model'])
          end
        end
      end

      # A default is only a default as far as the endpoint backs it: one the listing does not carry
      # would send the connection off with a model its first request fails on, so the empty option
      # names no model at all rather than that one.
      context 'when the models listed do not carry the adapter defaults' do
        before do
          allow(AI::Provider::OpenAI).to receive_messages(default_model: 'adapter-model', recommended_embedding_model: 'adapter-embed')
        end

        it 'names no default instead of one the provider does not serve', :aggregate_failures do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('OpenAI')
            fill_in 'name',  with: 'openai'
            fill_in 'Token', with: 'test-token'

            click_on 'Next'
          end

          in_modal disappears: false do
            # Nothing answers for an empty model field here - the adapter default the request would
            # otherwise resolve to is the very model this listing does not carry - so the field
            # offers no empty answer and starts on a model the endpoint serves.
            expect(page).to have_select('config.model', options: ['gpt-4.1'], selected: 'gpt-4.1')

            # The embedding model keeps its empty option: leaving it unnamed is a valid answer that
            # resolves to no model at all (see AI::Provider#embedding_model!).
            expect(page).to have_select('config.embedding_model', options: ['-', 'text-embedding-3-small'])

            # And the OCR option names the model the connection actually opens on, rather than the
            # unserved default of the adapter or no model at all.
            expect(page).to have_select('config.ocr_model', options: ['Default (gpt-4.1)', 'gpt-4.1'])

            # No model behind the empty option leaves nothing to describe, so the numbers of one
            # are not asked for either.
            expect(page).to have_no_field('Embedding dimensions')
          end
        end
      end

      # The provider whose catalogue is the admin's own: an Ollama that never pulled the model the
      # adapter falls back to serves it no more than it serves anything else that is not on disk.
      # Its model field is optional (only the URL is required), so an empty answer used to be
      # pre-selected and labelled '-' - while a config without a model still resolved to that very
      # model at request time, which nothing between the wizard and the first prompt would have
      # caught (#ping! reads the base URL, and there is no temperature probe).
      context 'when the endpoint has not pulled the model the adapter falls back to' do
        let(:model_list) { { 'models' => [{ 'model' => 'llama3.2:latest' }, { 'model' => 'bge-m3:latest' }] } }

        it 'demands a model the endpoint serves instead of an empty answer', :aggregate_failures do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('Ollama')
            fill_in 'name', with: 'ollama'
            fill_in 'URL',  with: 'http://localhost:11434'

            click_on 'Next'
          end

          in_modal disappears: true do
            expect(page).to have_select('config.model', options: ['llama3.2:latest'], selected: 'llama3.2:latest')

            click_on 'Submit'
          end

          # The model the connection runs on is the one the admin saw, not the one it would have
          # silently resolved to.
          expect(AI::ProviderConnection.find_by(name: 'ollama').config)
            .to include('model' => 'llama3.2:latest')
        end
      end

      it 'keeps the credentials on the way back from the model step' do
        click '[data-type=new]'

        in_modal disappears: true do
          find('select[name=provider]').select('OpenAI')
          fill_in 'name',  with: 'openai'
          fill_in 'Token', with: 'test-token'

          click_on 'Next'
        end

        in_modal disappears: true do
          find('select[name="config.model"]').select('gpt-4.1')

          click_on 'Back'
        end

        in_modal disappears: true do
          expect(page).to have_field('name', with: 'openai').and(have_field('Token', with: 'test-token'))

          click_on 'Next'
        end

        in_modal disappears: false do
          expect(page).to have_select('config.model', selected: 'gpt-4.1')
        end
      end

      # What was entered for the provider left behind must not end up in the payload of the one
      # that replaced it - not even the model of a step the admin already visited.
      it 'submits only the fields of the provider that ends up selected' do
        click '[data-type=new]'

        in_modal disappears: true do
          find('select[name=provider]').select('OpenAI')
          fill_in 'name',  with: 'switched'
          fill_in 'Token', with: 'test-token'

          click_on 'Next'
        end

        in_modal disappears: true do
          find('select[name="config.model"]').select('gpt-4.1')

          click_on 'Back'
        end

        in_modal disappears: true do
          find('select[name=provider]').select('Ollama')
          fill_in 'URL', with: 'http://localhost:11434'

          click_on 'Next'
        end

        in_modal disappears: true do
          # A field the new provider has as well keeps what was entered for the previous one,
          # exactly as the single step dialog did - the dropdown carries the value the new list
          # does not know rather than dropping it.
          expect(page).to have_select('config.model', selected: 'gpt-4.1')

          find('select[name="config.model"]').select('mistral-small3.2')

          click_on 'Submit'
        end

        connection = AI::ProviderConnection.find_by(name: 'switched')

        expect(connection).to have_attributes(provider: 'ollama')
        expect(connection.config).to include('url' => 'http://localhost:11434', 'model' => 'mistral-small3.2')

        # The token of the provider left behind has no field on this one, and no place in its
        # config either.
        expect(connection.config).not_to include('token')
      end

      # Reading an image needs a model that can see one, and the listing says which of them can.
      context 'when the provider serves a model that reads images' do
        let(:model_list) { { 'data' => [{ 'id' => 'gpt-4.1' }, { 'id' => 'mistral-large-2512' }] } }

        it 'offers the vision models for OCR and every chat model to run on' do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('OpenAI')
            fill_in 'name',  with: 'openai'
            fill_in 'Token', with: 'test-token'

            click_on 'Next'
          end

          in_modal disappears: false do
            expect(page)
              .to have_select('config.model', options: ['Default (gpt-4.1)', 'gpt-4.1', 'mistral-large-2512'])
              .and(have_select('config.ocr_model', options: ['Default (gpt-4.1)', 'gpt-4.1']))
          end
        end

        # An unnamed OCR model means the model of the connection reads the image, so the empty
        # option has to keep naming whichever model that is.
        it 'follows the model of the connection with the OCR default' do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('OpenAI')
            fill_in 'name',  with: 'openai'
            fill_in 'Token', with: 'test-token'

            click_on 'Next'
          end

          in_modal disappears: false do
            find('select[name="config.model"]').select('mistral-large-2512')

            expect(page).to have_select('config.ocr_model', options: ['Default (mistral-large-2512)', 'gpt-4.1'])

            # Back to naming no model of its own, which leaves the one the provider falls back to.
            find('select[name="config.model"]').select('Default (gpt-4.1)')

            expect(page).to have_select('config.ocr_model', options: ['Default (gpt-4.1)', 'gpt-4.1'])
          end
        end
      end

      # Vision is reported by few providers and guessed from the id for the rest, so a list without
      # any of it says nothing about what those models can read.
      context 'when the provider flags no model as reading images' do
        let(:model_list) { { 'data' => [{ 'id' => 'mistral-large-2512' }] } }

        it 'offers the chat models for OCR rather than an empty dropdown' do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('OpenAI')
            fill_in 'name',  with: 'openai'
            fill_in 'Token', with: 'test-token'

            click_on 'Next'
          end

          in_modal disappears: false do
            # This listing does not carry the model the adapter falls back to, so the model field
            # offers no empty answer and opens on the one model it lists - which is what reads the
            # image where no OCR model is named.
            expect(page)
              .to have_select('config.model', options: ['mistral-large-2512'])
              .and(have_select('config.ocr_model', options: ['Default (mistral-large-2512)', 'mistral-large-2512']))
          end
        end
      end

      # A custom endpoint serves whatever was deployed there, so there is no recommendation to
      # pre-fill - and nothing to demand of the admin either.
      context 'when a provider without a recommendation lists no models' do
        let(:model_list) { { 'data' => [] } }

        it 'does not demand an embedding model' do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('Custom (OpenAI Compatible)')
            fill_in 'name', with: 'custom'
            fill_in 'URL',  with: 'http://localhost:1234/v1'

            click_on 'Next'
          end

          in_modal disappears: true do
            # No model to describe, so nothing describing it is asked for either.
            expect(page)
              .to have_field('Embedding Model', with: '')
              .and(have_no_field('Embedding dimensions'))
              .and(have_no_field('Context window size'))

            # By name: a required field carries an asterisk, so its label no longer matches
            # 'Model' exactly and the embedding and OCR fields make it ambiguous.
            fill_in 'config.model', with: 'llama-3.1-8b-instruct'

            click_on 'Submit'
          end

          expect(AI::ProviderConnection.find_by(name: 'custom'))
            .to have_attributes(provider: 'custom_open_ai', default_embedding: false)
        end
      end

      # The empty option of a provider with no recommendation behind it ('-') names no model at
      # all, so the numbers describing one have nothing to describe: they leave the form, and the
      # connection is stored without them.
      context 'when a provider without a recommendation lists an embedding model' do
        let(:model_list) { { 'data' => [{ 'id' => 'llama-3.1-8b-instruct' }, { 'id' => 'bge-m3' }] } }

        it 'asks for the embedding metadata of a picked model alone' do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('Custom (OpenAI Compatible)')
            fill_in 'name', with: 'custom'
            fill_in 'URL',  with: 'http://localhost:1234/v1'

            click_on 'Next'
          end

          in_modal disappears: true do
            expect(page)
              .to have_select('config.embedding_model', options: ['-', 'bge-m3'], selected: '-')
              .and(have_no_field('Embedding dimensions'))
              .and(have_no_field('Context window size'))

            find('select[name="config.embedding_model"]').select('bge-m3')

            expect(page)
              .to have_field('Embedding dimensions', with: AI::Provider::EMBEDDING_SIZES['bge-m3'])
              .and(have_field('Context window size', with: AI::Provider::EMBEDDING_INPUT_LIMITS['bge-m3']))

            # Back to naming no model, which takes the numbers with it - down to the value they
            # were filled with, which must not reach the config of a connection that embeds nothing.
            find('select[name="config.embedding_model"]').select('-')

            expect(page).to have_no_field('Embedding dimensions')

            click_on 'Submit'
          end

          expect(AI::ProviderConnection.find_by(name: 'custom').config.keys)
            .not_to include('embedding_size', 'embedding_input_limit')
        end

        # The model step hands its fields to the credential step and gets them back on the way
        # forward, so a field it removed since has to be dropped from that baggage as well.
        it 'drops the metadata a step transition carried along' do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('Custom (OpenAI Compatible)')
            fill_in 'name', with: 'custom'
            fill_in 'URL',  with: 'http://localhost:1234/v1'

            click_on 'Next'
          end

          in_modal disappears: true do
            find('select[name="config.embedding_model"]').select('bge-m3')

            expect(page).to have_field('Embedding dimensions', with: AI::Provider::EMBEDDING_SIZES['bge-m3'])

            click_on 'Back'
          end

          in_modal disappears: true do
            click_on 'Next'
          end

          in_modal disappears: true do
            expect(page).to have_select('config.embedding_model', selected: 'bge-m3')

            find('select[name="config.embedding_model"]').select('-')

            expect(page).to have_no_field('Embedding dimensions')

            click_on 'Submit'
          end

          expect(AI::ProviderConnection.find_by(name: 'custom').config.keys)
            .not_to include('embedding_size', 'embedding_input_limit')
        end
      end

      # A required field gets no empty option at all; in case there is no fallback it would start on it,
      # labelled '-' with no default behind it, and on submit it will store no choice for the model
      # resulting in an empty config.
      context 'when a provider that requires the model lists models' do
        let(:model_list) { { 'data' => [{ 'id' => 'llama-3.1-8b-instruct' }, { 'id' => 'qwen3-8b' }] } }

        it 'starts the model dropdown on a real model instead of an empty answer' do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('Custom (OpenAI Compatible)')
            fill_in 'name', with: 'custom'
            fill_in 'URL',  with: 'http://localhost:1234/v1'

            click_on 'Next'
          end

          in_modal disappears: true do
            expect(page).to have_select('config.model',
                                        options:  %w[llama-3.1-8b-instruct qwen3-8b],
                                        selected: 'llama-3.1-8b-instruct')

            click_on 'Submit'
          end

          expect(AI::ProviderConnection.find_by(name: 'custom').config)
            .to include('model' => 'llama-3.1-8b-instruct')
        end
      end

      # A listing without an embedding model in it is an answer, not a gap: the provider serves
      # none, so the field neither offers the recommendation nor demands a model.
      context 'when the provider lists no embedding model' do
        let(:model_list) { { 'data' => [{ 'id' => 'gpt-4.1' }] } }

        it 'leaves the embedding model an empty, optional text field' do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('OpenAI')
            fill_in 'name',  with: 'openai'
            fill_in 'Token', with: 'test-token'

            click_on 'Next'
          end

          in_modal disappears: true do
            expect(page)
              .to have_select('config.model', options: ['Default (gpt-4.1)', 'gpt-4.1'])
              .and(have_field('Embedding Model', with: ''))
              .and(have_text('The provider offered no matching model for this field, so it has to be entered manually.'))

            find('select[name="config.model"]').select('gpt-4.1')

            click_on 'Submit'
          end

          connection = AI::ProviderConnection.find_by(name: 'openai')

          # The listing said the provider serves no embedding model, so the seeding respects the
          # deliberately empty choice: no recommendation written, no semantic search flag.
          expect(connection).to have_attributes(default_embedding: false)
          expect(connection.config).not_to have_key('embedding_model')
        end
      end

      # The recommendation is what the empty option names for as long as the endpoint serves it.
      # This listing carries an embedding model, just not that one - so the option names no model,
      # and what the connection embeds with is one the admin picks off the dropdown.
      context 'when the provider serves an embedding model other than the recommended one' do
        let(:model_list) { { 'data' => [{ 'id' => 'gpt-4.1' }, { 'id' => 'bge-m3' }] } }

        it 'offers the listed model instead of naming the recommendation', :aggregate_failures do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('OpenAI')
            fill_in 'name',  with: 'openai'
            fill_in 'Token', with: 'test-token'

            click_on 'Next'
          end

          in_modal disappears: true do
            expect(page)
              .to have_select('config.embedding_model', options: ['-', 'bge-m3'])
              .and(have_select('config.embedding_model', selected: '-'))

            # No model behind the empty option leaves nothing to describe, so the numbers of one
            # are not asked for either.
            expect(page).to have_no_field('Embedding dimensions')

            # A picked model is sized off the listing, without a request of its own.
            find('select[name="config.embedding_model"]').select('bge-m3')

            expect(page)
              .to have_field('Embedding dimensions', with: AI::Provider::EMBEDDING_SIZES['bge-m3'])
              .and(have_field('Context window size', with: AI::Provider::EMBEDDING_INPUT_LIMITS['bge-m3']))

            find('select[name="config.model"]').select('gpt-4.1')

            click_on 'Submit'
          end

          connection = AI::ProviderConnection.find_by(name: 'openai')

          # What the connection embeds with is the model that was picked - the recommendation the
          # endpoint was seen not to serve never enters the config, by the dialog or the seeding.
          expect(connection).to have_attributes(default_embedding: true)
          expect(connection.config).to include('embedding_model' => 'bge-m3')
        end
      end

      # Stored without them, the connection fails vector table creation later with an error naming
      # anything but the model that is missing them.
      context 'when no source knows the size of the embedding model' do
        let(:model_list) { { 'data' => [{ 'id' => 'gpt-4.1' }, { 'id' => 'homegrown-embed' }] } }

        it 'requires the dimensions and the context window size to be entered' do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('OpenAI')
            fill_in 'name',  with: 'openai'
            fill_in 'Token', with: 'test-token'

            click_on 'Next'
          end

          in_modal disappears: false do
            find('select[name="config.embedding_model"]').select('homegrown-embed')

            expect(page).to have_field('Embedding dimensions', with: '')

            click_on 'Submit'

            expect(page)
              .to have_css('.has-error [name="config.embedding_size"]')
              .and(have_css('.has-error [name="config.embedding_input_limit"]'))
              .and(have_text('is required'))
          end

          expect(AI::ProviderConnection).not_to exist
        end

        # Zero is no vector length and no token budget either: the vector table cannot be built
        # with such a dimension, and the chunker raises on a budget that leaves no room for content.
        it 'refuses a size that is not a positive number', :aggregate_failures do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('OpenAI')
            fill_in 'name',  with: 'openai'
            fill_in 'Token', with: 'test-token'

            click_on 'Next'
          end

          in_modal disappears: false do
            find('select[name="config.embedding_model"]').select('homegrown-embed')

            fill_in 'Embedding dimensions', with: '0'
            fill_in 'Context window size',  with: '-1'

            click_on 'Submit'

            expect(page)
              .to have_css('.has-error [name="config.embedding_size"]')
              .and(have_css('.has-error [name="config.embedding_input_limit"]'))
              .and(have_text('must be a positive number'))
          end

          expect(AI::ProviderConnection).not_to exist
        end
      end

      # The credentials are what the model list is fetched with, so the wizard cannot advance
      # without them.
      it 'refuses to advance without the credentials of the provider' do
        click '[data-type=new]'

        in_modal disappears: false do
          find('select[name=provider]').select('OpenAI')
          fill_in 'name', with: 'openai'

          click_on 'Next'

          expect(page).to have_css('.has-error [name="config.token"]')
        end
      end

      it 'names the reason the provider rejected the credentials with' do
        allow(UserAgent).to receive(:get).and_return(UserAgent::Result.new(success: false, code: 401))

        click '[data-type=new]'

        in_modal disappears: false do
          find('select[name=provider]').select('OpenAI')
          fill_in 'name',  with: 'rejected-conn'
          fill_in 'Token', with: 'invalid-token'

          click_on 'Next'

          # Still on the credential step, where the rejected key can be corrected.
          expect(page)
            .to have_text('The model list could not be fetched: Invalid API key')
            .and(have_field('Token', with: 'invalid-token'))
        end

        expect(AI::ProviderConnection).not_to exist
      end

      # The listing succeeds here, so the credential step lets the admin through - the endpoint
      # itself is only tested when the connection is saved.
      it 'refuses a connection the provider does not accept' do
        allow(UserAgent).to receive(:post).and_return(UserAgent::Result.new(success: false, code: 401))

        click '[data-type=new]'

        in_modal disappears: true do
          find('select[name=provider]').select('OpenAI')
          fill_in 'name',  with: 'rejected-conn'
          fill_in 'Token', with: 'invalid-token'

          click_on 'Next'
        end

        in_modal disappears: false do
          click_on 'Submit'

          expect(page).to have_text('Invalid API key')
        end

        expect(AI::ProviderConnection).not_to exist
      end

      it 'shows provider specific credential fields' do
        click '[data-type=new]'

        in_modal disappears: false do
          find('select[name=provider]').select('Ollama')
          expect(page)
            .to have_field('URL')
            .and(have_no_field('Token'))
            .and(have_no_field('Embedding Model'))

          find('select[name=provider]').select('OpenAI')
          expect(page)
            .to have_field('Token')
            .and(have_no_field('URL'))
        end
      end

      it 'hides Zammad AI as a provider option on SaaS' do
        click '[data-type=new]'

        in_modal disappears: false do
          expect(page).to have_no_select('provider', with_options: ['Zammad AI'])
        end
      end

      context 'when self-hosted' do
        let(:self_hosted) { true }

        # Zammad AI picks its models itself, so there is no second step to advance to and the
        # credential step is the whole dialog.
        it 'saves the Zammad AI connection from the credential step' do
          click '[data-type=new]'

          in_modal disappears: true do
            find('select[name=provider]').select('Zammad AI')

            # No embedding model field: the service serves a fixed one, so there is nothing to pick.
            expect(page)
              .to have_field('Token')
              .and(have_no_field('Embedding Model'))
              .and(have_no_button('Next'))

            fill_in 'name',  with: 'zammad-ai'
            fill_in 'Token', with: 'test-token'

            click_on 'Submit'
          end

          expect(AI::ProviderConnection.find_by(name: 'zammad-ai')).to have_attributes(provider: 'zammad_ai')
        end
      end
    end

    # Without App.AIProviderConnection.description the generic index leaves the content area
    # blank when no provider exists yet.
    describe 'without any connection' do
      it 'explains the object instead of rendering an empty table' do
        within :active_content do
          expect(page).to have_text('Each provider includes a set of credentials for one provider endpoint')
        end
      end
    end

    describe 'managing connections' do
      let(:connection_one) { create(:ai_provider_connection, :default_chat, name: 'first-connection') }
      let(:connection_two) do
        create(:ai_provider_connection, name:   'second-connection',
                                        config: { token: 'secret-token', model: 'gpt-4o', embedding_model: 'text-embedding-3-small' })
      end

      before do
        connection_one && connection_two

        refresh
      end

      it 'sets another connection as the chat default' do
        row = find('tr', text: 'second-connection')
        row.find('.js-action').click
        row.find('[data-table-action="set-default-chat"]').click

        expect(page).to have_text('Default provider updated successfully.')

        expect(find('tr', text: 'second-connection')).to have_text('Default')
        expect(connection_two.reload.default_chat).to be(true)
        expect(connection_one.reload.default_chat).to be(false)
      end

      it 'keeps unsaved edits when switching the provider in the edit dialog' do
        find('td', text: 'second-connection').click

        in_modal disappears: false do
          fill_in 'name', with: 'renamed-connection'
          find('select[name=provider]').select('Ollama')

          expect(page).to have_field('name', with: 'renamed-connection')
        end
      end

      it 'opens the edit dialog pre-filled on the credential step' do
        find('td', text: 'second-connection').click

        in_modal disappears: false do
          expect(page)
            .to have_select('provider', selected: 'OpenAI')
            .and(have_field('name', with: 'second-connection'))
            # The stored token comes back as the mask, which the wizard submits unchanged - so
            # the model list is fetched without the admin re-entering the key.
            .and(have_field('Token', with: SensitiveParamsHelper::SENSITIVE_MASK))
            .and(have_no_field('Model'))
        end
      end

      it 'edits a connection through both wizard steps' do
        find('td', text: 'second-connection').click

        in_modal disappears: true do
          fill_in 'name', with: 'renamed-connection'

          click_on 'Next'
        end

        in_modal disappears: true do
          # The stored model is one the provider no longer lists, and the dropdown carries it
          # anyway: an edit must not silently drop the model the connection runs on.
          expect(page).to have_select('config.model', selected: 'gpt-4o')

          find('select[name="config.model"]').select('gpt-4.1')

          click_on 'Submit'
        end

        expect(connection_two.reload)
          .to have_attributes(name: 'renamed-connection')

        # The masked token resolved back to the stored one instead of overwriting it, and the
        # stored embedding model was sized on the way through.
        expect(connection_two.config).to include(
          'model'          => 'gpt-4.1',
          'token'          => 'secret-token',
          'embedding_size' => AI::Provider::EMBEDDING_SIZES['text-embedding-3-small'],
        )
      end

      # The connection serving semantic search cannot save without an embedding model
      # (AI::ProviderConnection#embedding_model_present_when_serving_embeddings), so its dialog
      # offers no empty option the submit would only reject.
      it 'offers no empty embedding option on the connection serving semantic search' do
        find('td', text: 'first-connection').click

        in_modal disappears: true do
          click_on 'Next'
        end

        in_modal disappears: false do
          expect(page).to have_select('config.embedding_model',
                                      options:  ['text-embedding-3-small'],
                                      selected: 'text-embedding-3-small')
        end
      end

      it 'moves the semantic search default to another connection', :aggregate_failures do
        # The oldest connection is promoted for every mode, so it starts out carrying the badge.
        expect(find('tr', text: 'first-connection')).to have_text('Semantic search')

        row = find('tr', text: 'second-connection')
        row.find('.js-action').click
        row.find('[data-table-action="set-default-embedding"]').click

        expect(page).to have_text('Default provider updated successfully.')

        expect(find('tr', text: 'second-connection')).to have_text('Semantic search')
        expect(connection_two.reload.default_embedding).to be(true)
        expect(connection_one.reload.default_embedding).to be(false)
      end

      # visible: :all - unavailable actions are not rendered at all, while the rendered ones stay
      # hidden until the menu is opened. A row down to a single action has no menu to open.
      it 'does not offer the semantic search default on the connection already serving it' do
        expect(find('tr', text: 'first-connection'))
          .to have_no_css('[data-table-action="set-default-embedding"]', visible: :all)
      end

      context 'when a connection cannot embed' do
        let(:connection_two) { create(:ai_provider_connection, name: 'anthropic-connection', provider: 'anthropic') }

        it 'does not offer the semantic search default for it' do
          expect(find('tr', text: 'anthropic-connection'))
            .to have_no_css('[data-table-action="set-default-embedding"]', visible: :all)
        end
      end

      # The action is gated on the AIProviders registry, which is a second source of truth next to
      # the adapter - and drifted from it once already for this very provider.
      context 'when a connection embeds through a custom endpoint' do
        let(:connection_two) do
          create(:ai_provider_connection, name:     'custom-connection', provider: 'custom_open_ai',
                                          config:   { url: 'http://localhost:1234/v1', model: 'llama', embedding_model: 'bge-m3' })
        end

        it 'offers the semantic search default for it' do
          expect(find('tr', text: 'custom-connection'))
            .to have_css('[data-table-action="set-default-embedding"]', visible: :all)
        end
      end

      it 'moves the image text recognition default to another connection', :aggregate_failures do
        row = find('tr', text: 'second-connection')
        row.find('.js-action').click
        row.find('[data-table-action="set-default-ocr"]').click

        expect(page).to have_text('Default provider updated successfully.')

        expect(find('tr', text: 'second-connection')).to have_text('Image text recognition')
        expect(connection_two.reload.default_ocr).to be(true)
        expect(connection_one.reload.default_ocr).to be(false)
      end

      it 'shows a status badge for a connection whose last provider call failed', :aggregate_failures do
        connection_two.record_status_error!('quota exceeded')

        refresh

        expect(find('tr', text: 'second-connection')).to have_css('.icon-status.superbad-color')
        expect(find('tr', text: 'first-connection')).to have_no_css('.icon-status.superbad-color')
      end

      it 'picks up a status change without a reload' do
        expect(find('tr', text: 'second-connection')).to have_no_css('.icon-status.superbad-color')

        connection_two.record_status_error!('quota exceeded')

        expect(find('tr', text: 'second-connection'))
          .to have_css('.icon-status.superbad-color', wait: 30)
      end

      # The tooltip sits on the cell, which is the only one in the table carrying a title.
      describe 'status badge tooltip' do
        let(:tooltip) { find('tr', text: 'second-connection').find('td[title]')[:title] }

        # The message is escaped exactly once, by the generic table row template: a raw provider
        # message reaches the title attribute verbatim, and neither breaks out of it nor arrives
        # HTML-encoded.
        it 'names the error of a failed provider call' do
          connection_two.record_status_error!('quota exceeded "<img src=x>" & more')

          refresh

          expect(tooltip)
            .to match(%r{\AConnection failed\.\nquota exceeded "<img src=x>" & more\nLast status at: \S})
        end

        it 'confirms a successful provider call' do
          connection_two.record_status_ok!

          refresh

          expect(tooltip).to match(%r{\AConnected\.\nLast status at: \S})
        end

        # Without this the yellow badge of a fresh or reconfigured connection reads as a warning.
        it 'explains a connection that was never used' do
          expect(tooltip).to eq('Provider not used at the moment.')
        end
      end

      it 'deletes a connection' do
        row = find('tr', text: 'second-connection')
        row.find('.js-action').click
        row.find('[data-table-action="delete"]').click

        in_modal do
          click_on 'Delete'
        end

        expect(page).to have_no_text('second-connection')
      end

      it 'enables the AI provider via the header toggle' do
        # The toggle is re-injected on every table render, and a render landing right after the
        # click takes the success notification with it - wait for the initial fetches to settle.
        await_empty_ajax_queue

        find('.js-ai-provider-toggle label').click

        expect(page).to have_text('AI provider configuration enabled successfully.')
        expect(Setting.get('ai_provider')).to be(true)
      end

      context 'with a platform provisioned Zammad AI connection on SaaS' do
        # Simulates the platform provisioning this connection outside the admin API.
        let(:connection_two) { build(:ai_provider_connection, name: 'zammad-ai', provider: 'zammad_ai').tap { |c| c.save(validate: false) } }

        it 'hides the delete action' do
          row = find('tr', text: 'zammad-ai')
          row.find('.js-action').click

          expect(row).to have_no_css('[data-table-action="delete"]')
          expect(row).to have_css('[data-table-action="set-default-chat"]')
        end
      end
    end
  end
end
