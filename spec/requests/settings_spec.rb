# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Settings', type: :request do

  let(:admin) do
    create(:admin)
  end
  let(:admin_api) do
    role_api = create(:role)
    role_api.permission_grant('admin.api')

    create(:admin, roles: [role_api])
  end
  let(:agent) do
    create(:agent)
  end
  let(:customer) do
    create(:customer)
  end

  describe 'request handling' do

    it 'does settings index with nobody' do

      # index
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['settings']).to be_falsey

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Authentication required')
    end

    it 'does settings index with admin' do

      # index
      authenticated_as(admin)
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy
      hit_api = false
      hit_product_name = false
      json_response.each do |setting|
        if setting['name'] == 'api_token_access'
          hit_api = true
        end
        if setting['name'] == 'product_name'
          hit_product_name = true
        end
      end
      expect(hit_api).to be(true)
      expect(hit_product_name).to be(true)

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq('product_name')

      setting = Setting.find_by(name: 'api_token_access')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq('api_token_access')

      # update
      setting = Setting.find_by(name: 'product_name')
      params = {
        id:            setting.id,
        name:          'some_new_name',
        state_current: setting.state_current,
        preferences:   {
          permission:   ['admin.branding', 'admin.some_new_permission'],
          some_new_key: true,
        }
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq('product_name')
      expect(json_response['preferences']['permission'].length).to eq(1)
      expect(json_response['preferences']['permission'][0]).to eq('admin.branding')
      expect(json_response['preferences']).not_to have_key('some_new_key')

      # update
      setting = Setting.find_by(name: 'api_token_access')
      params = {
        id:            setting.id,
        name:          'some_new_name',
        state_current: setting.state_current,
        preferences:   {
          permission:   ['admin.branding', 'admin.some_new_permission'],
          some_new_key: true,
        }
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq('api_token_access')
      expect(json_response['preferences']['permission'].length).to eq(1)
      expect(json_response['preferences']['permission'][0]).to eq('admin.api')
      expect(json_response['preferences']).not_to have_key('some_new_key')

      # delete
      setting = Setting.find_by(name: 'product_name')
      delete "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Not authorized (feature not possible)')
    end

    it 'performs masking and unmasking of sensitive settings' do
      idoit_config = {
        api_token: 'some_api_token',
        endpoint:  'https://idoit.example.com/i-doit/',
        client_id: '',
      }

      Setting.set('idoit_config', idoit_config)

      authenticated_as(admin)

      # Masks sensitive data when fetching by value hash key
      setting = Setting.find_by(name: 'idoit_config')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['state_current']['value']['api_token']).to eq(SensitiveParamsHelper::SENSITIVE_MASK)

      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response.find { it['name'] == 'idoit_config' }['state_current']['value']['api_token']).to eq(SensitiveParamsHelper::SENSITIVE_MASK)

      # Unmasks sensitive data when updating by value hask key
      params = {
        id:            setting.id,
        state_current: {
          value: idoit_config.merge(api_token: SensitiveParamsHelper::SENSITIVE_MASK, client_id: 'new_client_id'),
        }
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['state_current']['value']['api_token']).to eq(SensitiveParamsHelper::SENSITIVE_MASK)
      expect(Setting.get('idoit_config')).to include(api_token: 'some_api_token', client_id: 'new_client_id')

      # Masks sensitive data when fetching by name
      setting = Setting.find_by(name: 'proxy_password')
      Setting.set('proxy_password', 'some_password')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['state_current']['value']).to eq(SensitiveParamsHelper::SENSITIVE_MASK)

      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response.find { it['name'] == 'proxy_password' }['state_current']['value']).to eq(SensitiveParamsHelper::SENSITIVE_MASK)

      # Unmasks sensitive data when updating by name
      params = {
        id:            setting.id,
        state_current: {
          value: SensitiveParamsHelper::SENSITIVE_MASK,
        }
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['state_current']['value']).to eq(SensitiveParamsHelper::SENSITIVE_MASK)
      expect(Setting.get('proxy_password')).to eq('some_password')

      # Updates sensitive data when updating by name
      params = {
        id:            setting.id,
        state_current: {
          value: 'new_password',
        }
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['state_current']['value']).to eq(SensitiveParamsHelper::SENSITIVE_MASK)
      expect(Setting.get('proxy_password')).to eq('new_password')

      # Does not mask sensitive-matching names that are in the NOT_SENSITIVE_NAMES list
      setting = Setting.find_by(name: 'user_lost_password')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['state_current']['value']).to be(true)

      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response.find { it['name'] == 'user_lost_password' }['state_current']['value']).to be(true)
    end

    # The key is only masked because it is spelled `api_key`, so a rename would leak it to every
    # reader of this endpoint without anything else failing.
    it 'masks the API key of the translation service but not its URL' do
      url = 'https://translate.example.com'

      stub_hostname_resolution(url)
      stub_request(:get, "#{url}/languages")
        .to_return(status: 200, body: [{ code: 'en' }].to_json, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, "#{url}/translate")
        .to_return(status: 200, body: { translatedText: 'Zammad' }.to_json, headers: { 'Content-Type' => 'application/json' })

      Setting.set('content_translation_service_config', { 'provider' => 'libre_translate', 'url' => url, 'api_key' => 'secret-key' })

      authenticated_as(admin)

      setting = Setting.find_by(name: 'content_translation_service_config')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response['state_current']['value']).to include(
        'api_key' => SensitiveParamsHelper::SENSITIVE_MASK,
        'url'     => url,
      )

      # The form sends the mask back unchanged, and the connection test now runs on what is
      # unmasked - so a key that stayed masked would refuse every further save of this form.
      params = {
        id:            setting.id,
        state_current: {
          value: { 'provider' => 'libre_translate', 'url' => url, 'api_key' => SensitiveParamsHelper::SENSITIVE_MASK },
        }
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json

      expect(response).to have_http_status(:ok)
      expect(Setting.get('content_translation_service_config')).to include('api_key' => 'secret-key')
    end

    it 'masks the API key of DeepL as well' do
      stub_request(:post, 'https://api-free.deepl.com/v2/translate')
        .to_return(status: 200, body: { translations: [{ text: 'Hallo' }] }.to_json, headers: { 'Content-Type' => 'application/json' })

      Setting.set('content_translation_service_config', { 'provider' => 'deepl', 'api_key' => 'secret-key', 'tier' => 'free' })

      authenticated_as(admin)

      setting = Setting.find_by(name: 'content_translation_service_config')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json

      expect(json_response['state_current']['value']).to include(
        'api_key' => SensitiveParamsHelper::SENSITIVE_MASK,
        'tier'    => 'free',
      )
    end

    it 'does settings index with admin-api' do

      # index
      authenticated_as(admin_api)
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy
      hit_api = false
      hit_product_name = false
      json_response.each do |setting|
        if setting['name'] == 'api_token_access'
          hit_api = true
        end
        if setting['name'] == 'product_name'
          hit_product_name = true
        end
      end
      expect(hit_api).to be(true)
      expect(hit_product_name).to be(false)

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Not authorized (required ["admin.branding"])!')

      setting = Setting.find_by(name: 'api_token_access')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq('api_token_access')

      # update
      setting = Setting.find_by(name: 'product_name')
      params = {
        id:          setting.id,
        name:        'some_new_name',
        preferences: {
          permission:   ['admin.branding', 'admin.some_new_permission'],
          some_new_key: true,
        }
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Not authorized (required ["admin.branding"])!')

      # update
      setting = Setting.find_by(name: 'api_token_access')
      params = {
        id:            setting.id,
        name:          'some_new_name',
        state_current: setting.state_current,
        preferences:   {
          permission:   ['admin.branding', 'admin.some_new_permission'],
          some_new_key: true,
        }
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq('api_token_access')
      expect(json_response['preferences']['permission'].length).to eq(1)
      expect(json_response['preferences']['permission'][0]).to eq('admin.api')
      expect(json_response['preferences']).not_to have_key('some_new_key')

      # delete
      setting = Setting.find_by(name: 'product_name')
      delete "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Not authorized (feature not possible)')
    end

    it 'does settings index with agent' do

      # index
      authenticated_as(agent)
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['settings']).to be_falsey
      expect(json_response['error']).to eq('User authorization failed.')

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('User authorization failed.')
    end

    it 'does settings index with customer' do

      # index
      authenticated_as(customer)
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['settings']).to be_falsey
      expect(json_response['error']).to eq('User authorization failed.')

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('User authorization failed.')

      # delete
      setting = Setting.find_by(name: 'product_name')
      delete "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('User authorization failed.')
    end

    it 'protected setting not existing in list' do
      authenticated_as(admin)
      get '/api/v1/settings', params: {}, as: :json
      expect(json_response.detect { |setting| setting['name'] == 'application_secret' }).to be_nil
    end

    it 'can not show protected setting' do
      setting = Setting.find_by(name: 'application_secret')
      authenticated_as(admin)
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'can not update protected setting', :aggregate_failures do
      setting = Setting.find_by(name: 'application_secret')
      params = {
        id:    setting.id,
        state: 'Examaple'
      }

      authenticated_as(admin)
      expect { put "/api/v1/settings/#{setting.id}", params: params, as: :json }
        .not_to change { setting.reload.state_current }
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Not authorized (setting is protected)!')
    end

    context 'when the SSO setting is updated', authenticated_as: :admin do
      let(:setting) { Setting.find_by(name: 'auth_sso') }

      it 'updates the setting' do
        expect { put "/api/v1/settings/#{setting.id}", params: { id: setting.id, state_current: { value: true } }, as: :json }
          .to change { Setting.get('auth_sso') }.to(true)
      end

      context 'when running as an online service' do
        before { Setting.set('system_online_service', true) }

        it 'can not update the setting', :aggregate_failures do
          expect { put "/api/v1/settings/#{setting.id}", params: { id: setting.id, state_current: { value: true } }, as: :json }
            .not_to change { Setting.get('auth_sso') }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when reset is used', authenticated_as: :admin do
      it 'can not reset protected setting', :aggregate_failures do
        setting = Setting.find_by(name: 'application_secret')
        expect { post "/api/v1/settings/reset/#{setting.id}", params: {}, as: :json }
          .not_to change { setting.reload.state_current }
        expect(response).to have_http_status(:forbidden)
      end

      it 'reset a setting', :aggregate_failures do
        setting = Setting.find_by(name: 'product_name')

        setting.update(state_current: { value: 'Other name' })

        post "/api/v1/settings/reset/#{setting.id}", params: {}, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to be_a(Hash)
        expect(json_response['state_current']).to eq(setting[:state_initial])
      end
    end
  end

  describe 'MCP server switch' do
    let(:setting) { Setting.find_by(name: 'api_mcp_access') }
    let(:admin_branding) do
      role = create(:role)
      role.permission_grant('admin.branding')

      create(:admin_only, roles: [role])
    end

    def switch_on
      put "/api/v1/settings/#{setting.id}", params: { state_current: { value: true } }, as: :json
    end

    it 'is changed with the API permission', authenticated_as: :admin_api do
      expect { switch_on }.to change { Setting.get('api_mcp_access') }.from(false).to(true)
      expect(response).to have_http_status(:ok)
    end

    it 'is not changed with another admin permission', authenticated_as: :admin_branding do
      expect { switch_on }.not_to change { Setting.get('api_mcp_access') }
      expect(response).to have_http_status(:forbidden)
    end

    it 'is not changed by an agent', authenticated_as: :agent do
      expect { switch_on }.not_to change { Setting.get('api_mcp_access') }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PUT /api/v1/settings/:id with attributes other than the state' do
    let(:admin_security) do
      role_security = create(:role)
      role_security.permission_grant('admin.security')

      create(:admin, roles: [role_security])
    end
    let(:setting) { Setting.find_by(name: 'user_lost_password') }
    let(:params) do
      {
        name:          'changed_name',
        area:          'Changed::Base',
        title:         'Changed title',
        description:   'Changed description',
        options:       { form: [] },
        frontend:      false,
        state_initial: { value: false },
        state_current: { value: false },
        preferences:   {
          protected:       true,
          transformations: ['Setting::Transformation::SanitizeHtml'],
          validations:     ['Setting::Validation::TimeZone'],
          cache:           ['some_cache_key'],
          some_new_key:    true,
        },
      }
    end

    shared_examples 'updating only the state' do
      it 'ignores the other attributes and keeps the setting reachable', :aggregate_failures do
        expect { put "/api/v1/settings/#{setting.id}", params: params, as: :json }
          .to not_change { setting.reload.attributes.except('state_current', 'updated_at') }

        expect(response).to have_http_status(:ok)
        expect(setting.state_current['value']).to be(false)

        get "/api/v1/settings/#{setting.id}", as: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with a partial admin', authenticated_as: :admin_security do
      it_behaves_like 'updating only the state'
    end

    context 'with a full admin', authenticated_as: :admin do
      it_behaves_like 'updating only the state'
    end
  end

  describe 'PUT /api/v1/settings/:id with keys other than the value in the state', authenticated_as: :admin do
    let(:setting) { Setting.find_by(name: 'user_lost_password') }

    it 'stores only the value', :aggregate_failures do
      put "/api/v1/settings/#{setting.id}", params: { state_current: { value: false, some_new_key: { some: 'value' } } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(setting.reload.state_current).to eq({ 'value' => false })
    end

    [{ some_new_key: true }, false].each do |state_current|
      context "with #{state_current.inspect} as the state" do
        it 'rejects the request', :aggregate_failures do
          expect { put "/api/v1/settings/#{setting.id}", params: { state_current: state_current }, as: :json }
            .to not_change { setting.reload.state_current }

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  describe 'PUT /api/v1/settings/image/:id' do
    let(:admin_branding) do
      role_branding = create(:role)
      role_branding.permission_grant('admin.branding')

      create(:admin, roles: [role_branding])
    end
    let(:product_logo) { Setting.find_by(name: 'product_logo') }
    let(:params)       { { logo: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==' } }

    context 'with another setting the user may update', authenticated_as: :admin_api do
      it 'does not change the product logo', :aggregate_failures do
        setting = Setting.find_by(name: 'api_token_access')

        expect { put "/api/v1/settings/image/#{setting.id}", params: params, as: :json }
          .to not_change { product_logo.reload.state_current }
          .and not_change { Service::SystemAssets::ProductLogo.sendable_asset.content }
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq('Only the product logo can be updated with an image.')
      end
    end

    context 'with another branding setting', authenticated_as: :admin_branding do
      it 'does not change the setting', :aggregate_failures do
        setting = Setting.find_by(name: 'product_name')

        expect { put "/api/v1/settings/image/#{setting.id}", params: params, as: :json }
          .not_to change { setting.reload.state_current }
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq('Only the product logo can be updated with an image.')
      end
    end

    context 'without the branding permission', authenticated_as: :admin_api do
      it 'does not change the product logo', :aggregate_failures do
        expect { put "/api/v1/settings/image/#{product_logo.id}", params: params, as: :json }
          .not_to change { product_logo.reload.state_current }
        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('Not authorized (required ["admin.branding"])!')
      end
    end

    context 'with the branding permission', authenticated_as: :admin_branding do
      it 'changes the product logo', :aggregate_failures do
        expect { put "/api/v1/settings/image/#{product_logo.id}", params: params, as: :json }
          .to change { product_logo.reload.state_current }
        expect(response).to have_http_status(:ok)
        expect(json_response['result']).to eq('ok')
      end
    end
  end

  describe 'access by admin permission' do
    let(:security_admin) do
      role = create(:role)
      role.permission_grant('admin.security')

      create(:user, roles: [role])
    end
    let(:developer_mode) { Setting.find_by(name: 'developer_mode') }
    let(:system_bcc)     { Setting.find_by(name: 'system_bcc') }

    context 'with a partial admin permission', authenticated_as: :security_admin do
      it 'lists only the settings of that permission', :aggregate_failures do
        get '/api/v1/settings', as: :json

        names = json_response.pluck('name')
        expect(names).to include('session_timeout')
        expect(names).not_to include('developer_mode', 'es_url', 'system_bcc')
      end

      it 'can update a setting of that permission', :aggregate_failures do
        setting = Setting.find_by(name: 'session_timeout')
        value   = setting.state_current['value'].merge('default' => '3600')

        put "/api/v1/settings/#{setting.id}", params: { state_current: { value: } }, as: :json

        expect(response).to have_http_status(:ok)
        expect(setting.reload.state_current['value']['default']).to eq('3600')
      end

      it 'can not show a setting reserved to full admins' do
        get "/api/v1/settings/#{system_bcc.id}", as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'can not update a setting reserved to full admins', :aggregate_failures do
        expect { put "/api/v1/settings/#{system_bcc.id}", params: { state_current: { value: 'archive@example.com' } }, as: :json }
          .not_to change { system_bcc.reload.state_current }
        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('Not authorized (required ["admin"])!')
      end

      it 'can not reset a setting reserved to full admins', :aggregate_failures do
        system_bcc.update!(state_current: { value: 'archive@example.com' })

        expect { post "/api/v1/settings/reset/#{system_bcc.id}", as: :json }
          .not_to change { system_bcc.reload.state_current }
        expect(response).to have_http_status(:forbidden)
      end

      it 'names full admin as required for a setting without a permission', :aggregate_failures do
        system_bcc.update!(preferences: {})

        get "/api/v1/settings/#{system_bcc.id}", as: :json

        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('Not authorized (required ["admin"])!')
      end

      it 'can not update the developer mode', :aggregate_failures do
        expect { put "/api/v1/settings/#{developer_mode.id}", params: { state_current: { value: true } }, as: :json }
          .not_to change { developer_mode.reload.state_current }
        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('Not authorized (required ["admin"])!')
      end
    end

    context 'with full admin permission', authenticated_as: :admin do
      it 'lists the settings reserved to full admins' do
        get '/api/v1/settings', as: :json

        expect(json_response.pluck('name')).to include('developer_mode', 'es_url', 'system_bcc')
      end

      it 'can update a setting reserved to full admins', :aggregate_failures do
        put "/api/v1/settings/#{system_bcc.id}", params: { state_current: { value: 'archive@example.com' } }, as: :json

        expect(response).to have_http_status(:ok)
        expect(system_bcc.reload.state_current['value']).to eq('archive@example.com')
      end
    end
  end

  describe 'PUT /api/v1/settings/:id with a backend class', authenticated_as: :delegated_admin do
    let(:delegated_admin) do
      role = create(:role)
      role.permission_grant(permission)

      create(:agent, roles: [Role.find_by(name: 'Agent'), role])
    end
    let(:setting) { Setting.find_by(name: setting_name) }

    def update_setting(value)
      put "/api/v1/settings/#{setting.id}", params: { id: setting.id, state_current: { value: value } }, as: :json
    end

    {
      'admin.security'    => ['auth_internal', { priority: 1, adapter: 'Hashie::Mash' }, 'Hashie::Mash'],
      'admin.system'      => ['geo_ip_backend', 'KnowledgeBase::MenuItem', 'KnowledgeBase::MenuItem'],
      'admin.ticket'      => %w[ticket_number JSON JSON],
      'admin.text_module' => ['Stats::TicketReopen', 'JSON', 'JSON'],
    }.each do |granted, (name, value, class_name)|
      context "with #{granted}" do
        let(:permission)   { granted }
        let(:setting_name) { name }

        it "rejects #{class_name} for #{name}", :aggregate_failures do
          expect { update_setting(value) }.not_to change { setting.reload.state_current }
          expect(response).to have_http_status(:unprocessable_content)
          expect(json_response['error']).to include("'#{class_name}' is not a valid backend for this setting.")
        end
      end
    end

    context 'with a backend of the setting' do
      let(:permission)   { 'admin.ticket' }
      let(:setting_name) { 'ticket_number' }

      it 'updates the setting', :aggregate_failures do
        expect { update_setting('Ticket::Number::Date') }.to change { Setting.get('ticket_number') }.to('Ticket::Number::Date')
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'vector index rebuild response', authenticated_as: :admin, performs_jobs: true do
    let(:connection) do
      create(:ai_provider_connection, :default_embedding, provider: 'open_ai',
                                                          config:   { token: 'a', embedding_model: 'text-embedding-3-small' })
    end
    let(:setting) { Setting.find_by(name: 'ai_provider') }

    before do
      connection
      Setting.set('ai_provider', true)
      Setting.set('vectordb_enabled', true)
      Service::AI::VectorDB::Embedding::Configuration.record_indexed(Service::AI::VectorDB::Embedding::Configuration.current)
      Setting.set('ai_provider', false)
      connection.update_columns(config: connection.config.merge('embedding_model' => 'text-embedding-3-large'))
      clear_jobs
    end

    it 'reports a rebuild that starts when AI providers are re-enabled', :aggregate_failures do
      put "/api/v1/settings/#{setting.id}",
          params: { state_current: { value: true } },
          as:     :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include(
        'id'                           => setting.id,
        'name'                         => 'ai_provider',
        'state_current'                => { 'value' => true },
        'vector_index_rebuild_started' => true,
      )
      expect(VectorIndexRebuildJob).to have_been_enqueued
    end
  end
end
