# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'GettingStarted', :aggregate_failures, type: :request do
  describe 'GET /api/v1/getting_started' do
    context 'when system is not yet set up' do
      it 'returns setup status without authentication' do
        get '/api/v1/getting_started', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          'setup_done' => false,
        )
      end
    end

    # A migration is started anonymously from the installer and imports users, so
    # it pushes the user count past the setup_done threshold while it runs. The
    # progress screens have to keep working without a user, but they read nothing
    # but import_mode and import_backend.
    context 'when a migration is running' do
      before do
        Setting.set('import_mode', true)
        Setting.set('import_backend', 'otrs')
        Setting.set('system_init_done', false)
        create_list(:customer, 3)
      end

      # The progress screens navigate by import_backend and stay on their screen
      # as long as import_mode is on, so both have to be answered.
      it 'answers an anonymous request with the migration information' do
        get '/api/v1/getting_started', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          'setup_done'     => true,
          'import_mode'    => true,
          'import_backend' => 'otrs',
        )
      end

      # An import only clears import_mode when it succeeds, so a failed or
      # abandoned migration leaves the window open with the imported groups and
      # addresses already in the database. It must not disclose them.
      it 'does not disclose the group or email address list to an anonymous request' do
        create(:group)

        get '/api/v1/getting_started', as: :json

        expect(json_response.keys).not_to include('groups', 'addresses', 'config', 'channel_driver')
      end

      # The importers assign the Admin role to imported users, so a migration
      # acquires admins while it runs. That must not close the window.
      it 'answers an anonymous request once the migration has imported an admin' do
        create(:admin)

        get '/api/v1/getting_started', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include('import_mode' => true)
      end

      # The window is not bounded in time, so it is reduced for everyone rather
      # than by role: during a migration no screen needs the wizard data, and a
      # user who does has the dedicated group and email address endpoints.
      context 'when authenticated as admin', authenticated_as: :admin do
        let(:admin) { create(:admin) }

        it 'returns the migration information only' do
          get '/api/v1/getting_started', as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response.keys).not_to include('groups', 'addresses', 'config', 'channel_driver')
        end
      end
    end

    # Regression guard for the unauthenticated disclosure fixed in 7.1.0. Only a
    # running migration is answered without a user, and an import refuses to start
    # once the setup is done (Import::Helper), so a real migration always has
    # import_mode on and system_init_done off. Every other combination of the two
    # has to stay closed, and each is reachable:
    #
    # - system_init_done is not monotonic, Service::System::CheckSetup resets it
    #   when it is set without an admin being present;
    # - an installed system can be left in import mode, which must not be enough
    #   on its own to open the payload.
    context 'when no migration is running' do
      before { create_list(:customer, 3) }

      [
        { import_mode: false, system_init_done: false },
        { import_mode: false, system_init_done: true },
        { import_mode: true,  system_init_done: true },
      ].each do |settings|
        context "with import_mode #{settings[:import_mode]} and system_init_done #{settings[:system_init_done]}" do
          before { settings.each { |name, value| Setting.set(name.to_s, value) } }

          it 'does not answer an anonymous request' do
            expect(User.admin_user_exists?(except_user_id: [1])).to be false

            get '/api/v1/getting_started', as: :json

            expect(response).to have_http_status(:forbidden)
          end
        end
      end
    end

    context 'when system is already set up' do
      let(:admin) { create(:admin) }

      before do
        # A set-up system always has an admin — Service::System::CheckSetup
        # refuses to consider the setup done without one — and setup_done
        # requires more than 2 users.
        admin
        create(:agent)
      end

      context 'when not authenticated' do
        it 'returns forbidden' do
          get '/api/v1/getting_started', as: :json

          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when authenticated as admin', authenticated_as: :admin do
        let!(:group) { create(:group, note: 'Internal group note') }

        it 'returns detailed setup information' do
          get '/api/v1/getting_started', as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response).to include(
            'setup_done'     => true,
            'groups'         => be_a(Array),
            'addresses'      => be_a(Array),
            'config'         => be_a(Hash),
            'channel_driver' => be_a(Hash),
          )
        end

        it 'returns the active groups with their full attributes' do
          get '/api/v1/getting_started', as: :json

          expect(json_response['groups']).to include(include('id' => group.id, 'note' => group.note))
        end
      end

      shared_examples 'denying the request' do
        it 'returns forbidden' do
          get '/api/v1/getting_started', as: :json

          expect(response).to have_http_status(:forbidden)
        end

        it 'does not disclose the group or email address list' do
          get '/api/v1/getting_started', as: :json

          expect(json_response.keys).not_to include('groups', 'addresses', 'config', 'channel_driver')
        end
      end

      context 'when authenticated as agent', authenticated_as: :agent do
        let(:agent) { create(:agent) }

        include_examples 'denying the request'
      end

      context 'when authenticated as customer', authenticated_as: :customer do
        let(:customer) { create(:customer) }

        include_examples 'denying the request'
      end
    end
  end

  describe 'GET /api/v1/getting_started/auto_wizard' do
    context 'when system is already set up' do
      let(:admin) { create(:admin) }

      before do
        admin
        create(:agent)
      end

      it 'returns forbidden when not authenticated' do
        get '/api/v1/getting_started/auto_wizard', as: :json

        expect(response).to have_http_status(:forbidden)
      end

      context 'when authenticated as admin', authenticated_as: :admin do
        it 'returns the setup information' do
          get '/api/v1/getting_started/auto_wizard', as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response).to include(
            'groups'    => be_a(Array),
            'addresses' => be_a(Array),
          )
        end
      end

      # The action reaches the same setup_done_payload as #index, so it has to be
      # gated for every role that #index denies.
      shared_examples 'denying the auto wizard request' do
        it 'returns forbidden' do
          get '/api/v1/getting_started/auto_wizard', as: :json

          expect(response).to have_http_status(:forbidden)
          expect(json_response.keys).not_to include('groups', 'addresses')
        end
      end

      context 'when authenticated as agent', authenticated_as: :agent do
        let(:agent) { create(:agent) }

        include_examples 'denying the auto wizard request'
      end

      context 'when authenticated as customer', authenticated_as: :customer do
        let(:customer) { create(:customer) }

        include_examples 'denying the auto wizard request'
      end
    end

    # Both actions share the migration window, so it has to be pinned down for
    # this one as well: reachable without a user, and carrying no wizard data.
    context 'when a migration is running' do
      before do
        Setting.set('import_mode', true)
        Setting.set('import_backend', 'otrs')
        Setting.set('system_init_done', false)
        create_list(:customer, 3)
      end

      it 'answers an anonymous request with the migration information' do
        get '/api/v1/getting_started/auto_wizard', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          'setup_done'     => true,
          'import_mode'    => true,
          'import_backend' => 'otrs',
        )
      end

      it 'does not disclose the group or email address list to an anonymous request' do
        create(:group)

        get '/api/v1/getting_started/auto_wizard', as: :json

        expect(json_response.keys).not_to include('groups', 'addresses', 'config', 'channel_driver')
      end
    end

    # The same three reachable combinations as for #index, which must not open
    # the payload here either.
    context 'when no migration is running' do
      before { create_list(:customer, 3) }

      [
        { import_mode: false, system_init_done: false },
        { import_mode: false, system_init_done: true },
        { import_mode: true,  system_init_done: true },
      ].each do |settings|
        context "with import_mode #{settings[:import_mode]} and system_init_done #{settings[:system_init_done]}" do
          before { settings.each { |name, value| Setting.set(name.to_s, value) } }

          it 'does not answer an anonymous request' do
            expect(User.admin_user_exists?(except_user_id: [1])).to be false

            get '/api/v1/getting_started/auto_wizard', as: :json

            expect(response).to have_http_status(:forbidden)
          end
        end
      end
    end
  end

  describe 'POST /api/v1/getting_started/base' do
    let(:admin) { create(:admin) }

    before { create(:agent) }

    context 'when not authenticated' do
      it 'returns forbidden' do
        post '/api/v1/getting_started/base', params: { url: 'https://example.com' }, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      before { authenticated_as(admin, via: :browser) }

      it 'sets system base information' do
        post '/api/v1/getting_started/base', params: { url: 'https://example.com', locale_default: 'en-us', timezone_default: 'UTC', organization: 'Test Corp' }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include('result' => 'ok')
      end

      it 'returns error for missing url' do
        post '/api/v1/getting_started/base', params: { locale_default: 'en-us' }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include('result' => 'invalid')
      end
    end

    context 'when authenticated as agent' do
      let(:agent) { create(:agent) }

      before { authenticated_as(agent, via: :browser) }

      it 'returns forbidden' do
        post '/api/v1/getting_started/base', params: { url: 'https://example.com' }, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
