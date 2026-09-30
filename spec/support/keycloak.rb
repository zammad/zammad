# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Talks to the admin API of the Keycloak service, which provides the realm "zammad" and the user "john.doe".
module ZammadSpecSupportKeycloak
  KEYCLOAK_USERNAME = 'john.doe'.freeze

  # Replaces the client, which also drops its client roles and their assignments.
  def keycloak_recreate_client(client_id:, client_json:)
    keycloak_admin_get("/clients?clientId=#{CGI.escape(client_id)}").each do |client|
      keycloak_admin_send(:delete, "/clients/#{client['id']}")
    end
    keycloak_admin_send(:post, '/clients', JSON.parse(client_json))

    keycloak_admin_get("/clients?clientId=#{CGI.escape(client_id)}").first['id']
  end

  def keycloak_create_client_roles(client_uuid, names)
    names.each do |name|
      keycloak_admin_send(:post, "/clients/#{client_uuid}/roles", { name: })
    end
  end

  def keycloak_assign_client_roles(client_uuid, names)
    keycloak_admin_send(:post, "/users/#{keycloak_user_id}/role-mappings/clients/#{client_uuid}", keycloak_client_roles(client_uuid, names))
  end

  def keycloak_revoke_client_roles(client_uuid, names)
    keycloak_admin_send(:delete, "/users/#{keycloak_user_id}/role-mappings/clients/#{client_uuid}", keycloak_client_roles(client_uuid, names))
  end

  # Ends all sessions of the user, so the next login shows the login form of Keycloak again.
  def keycloak_logout_user
    keycloak_admin_send(:post, "/users/#{keycloak_user_id}/logout")
  end

  def keycloak_login(path:)
    find_by_id('kc-form')
    expect(page).to have_current_path(path)
    expect(page).to have_css('#kc-form-login')

    within '#kc-form-login' do
      fill_in 'username', with: KEYCLOAK_USERNAME
      fill_in 'password', with: 'test'

      click_on 'Sign In'
    end

    expect(page).to have_no_text('Sign In')
  end

  def keycloak_admin_token
    response = keycloak_request!(
      :post,
      "#{ENV['KEYCLOAK_BASE_URL']}/realms/master/protocol/openid-connect/token",
      {
        grant_type: 'password',
        client_id:  'admin-cli',
        username:   ENV['KC_BOOTSTRAP_ADMIN_USERNAME'],
        password:   ENV['KC_BOOTSTRAP_ADMIN_PASSWORD'],
      },
    )

    JSON.parse(response.body)['access_token']
  end

  def keycloak_request!(method, url, params = {}, options = {})
    response = UserAgent.public_send(method, url, params, options)
    raise "Keycloak request #{method.upcase} #{url} failed: #{response.code} #{response.body}" if !response.success?

    response
  end

  private

  def keycloak_admin_get(path)
    keycloak_request!(:get, "#{ENV['KEYCLOAK_BASE_URL']}/admin/realms/zammad#{path}", {}, { json: true, bearer_token: keycloak_admin_token }).data
  end

  def keycloak_admin_send(method, path, payload = {})
    keycloak_request!(method, "#{ENV['KEYCLOAK_BASE_URL']}/admin/realms/zammad#{path}", payload, { json: true, jsonParseDisable: true, bearer_token: keycloak_admin_token })
  end

  def keycloak_user_id
    keycloak_admin_get("/users?username=#{KEYCLOAK_USERNAME}&exact=true").first['id']
  end

  def keycloak_client_roles(client_uuid, names)
    names.map { |name| keycloak_admin_get("/clients/#{client_uuid}/roles/#{CGI.escape(name)}") }
  end
end

RSpec.configure do |config|
  config.include ZammadSpecSupportKeycloak, integration_standalone: :saml
  config.include ZammadSpecSupportKeycloak, integration_standalone: :oidc
end
