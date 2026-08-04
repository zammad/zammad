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

    before do
      Setting.set('system_online_service', !self_hosted)

      result = UserAgent::Result.new(
        success: true,
        code:    200,
      )

      allow(UserAgent).to receive_messages(get: result, post: result)

      visit '/#ai/providers'
    end

    describe 'creating a connection' do
      it 'creates a connection via the dialog and marks it as default' do
        click '[data-type=new]'

        in_modal do
          find('select[name=provider]').select('OpenAI')

          expect(page)
            .to have_field('Token')
            .and(have_field('Model', placeholder: AI::Provider::OpenAI::DEFAULT_OPTIONS[:model]))
            .and(have_field('Embedding Model'))
            .and(have_field('OCR Model'))

          # The name is deliberately not pre-filled from the provider, it is up to the admin.
          expect(page).to have_field('name', with: '')

          fill_in 'name',  with: 'openai'
          fill_in 'Token', with: 'test-token'

          click_on 'Submit'
        end

        within :active_content do
          expect(page).to have_text('openai')

          # The first connection automatically becomes the default for every mode.
          expect(find('tr', text: 'openai')).to have_text('Default')
        end

        expect(AI::ProviderConnection.find_by(name: 'openai'))
          .to have_attributes(provider: 'open_ai', default_chat: true)
      end

      it 'refuses a connection the provider does not accept' do
        rejected = UserAgent::Result.new(success: false, code: 401)
        allow(UserAgent).to receive_messages(get: rejected, post: rejected)

        click '[data-type=new]'

        in_modal disappears: false do
          find('select[name=provider]').select('OpenAI')
          fill_in 'name',  with: 'rejected-conn'
          fill_in 'Token', with: 'invalid-token'

          click_on 'Submit'

          expect(page).to have_text('Invalid API key')
        end

        expect(AI::ProviderConnection).not_to exist
      end

      it 'shows provider specific configuration fields' do
        click '[data-type=new]'

        in_modal disappears: false do
          find('select[name=provider]').select('Ollama')
          expect(page)
            .to have_field('URL')
            .and(have_field('Embedding Model'))
            .and(have_no_field('Token'))

          find('select[name=provider]').select('OpenAI')
          expect(page)
            .to have_field('Token')
            .and(have_field('Model'))
            .and(have_no_field('URL'))
        end
      end

      it 'hides Zammad AI as a provider option on SaaS' do
        click '[data-type=new]'

        in_modal disappears: false do
          expect(page).to have_no_select('provider', with_options: ['Zammad AI'])
        end
      end

      it 'validates required fields' do
        click '[data-type=new]'

        in_modal disappears: false do
          find('select[name=provider]').select('OpenAI')

          click_on 'Submit'

          expect(page).to have_css('.has-error [name="config.token"]')
        end
      end

      context 'when self-hosted' do
        let(:self_hosted) { true }

        it 'shows the Zammad AI token field' do
          click '[data-type=new]'

          in_modal disappears: false do
            find('select[name=provider]').select('Zammad AI')
            expect(page).to have_field('Token')
          end
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
      let(:connection_two) { create(:ai_provider_connection, name: 'second-connection') }

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
