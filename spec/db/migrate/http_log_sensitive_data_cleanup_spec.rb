# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HttpLogSensitiveDataCleanup, :aggregate_failures, type: :db_migration do
  def create_http_log(data = {})
    HttpLog.without_callback(:save, :before, :filter_sensitive_data) do
      http_log = HttpLog.new(attributes_for(:http_log).merge(data))
      http_log.save!

      http_log
    end
  end

  let!(:http_log_bearer)  { create_http_log(request: { headers: 'Authorization: Bearer supersecrettoken' }) }
  let!(:http_log_basic)   { create_http_log(request: { headers: 'Authorization: Basic dXNlcjpwYXNzd29yZA==' }) }
  let!(:http_log_token)   { create_http_log(response: { body: 'access_token="anothersecret"' }) }
  let!(:http_log_api_key) { create_http_log(response: { body: 'api_key: "key-value"' }) }
  let!(:http_log_secret)  { create_http_log(request: { params: 'secret = "my_secret"' }) }
  let!(:http_log_cookie)  { create_http_log(request: { headers: 'Cookie: session_id=12345; user_id=67890' }) }
  let!(:http_log_query)   { create_http_log(request: { url: 'https://example.com/api?access_token=query_secret_token&other=param' }) }
  let!(:http_log_clean)   { create_http_log(request: { body: 'no secrets here' }) }

  it 'masks sensitive data in http_logs' do
    migrate

    expect(http_log_bearer.reload.request['headers']).to eq('Authorization: Bearer [FILTERED]')
    expect(http_log_basic.reload.request['headers']).to eq('Authorization: Basic [FILTERED]')
    expect(http_log_token.reload.response['body']).to eq('access_token="[FILTERED]"')
    expect(http_log_api_key.reload.response['body']).to eq('api_key: "[FILTERED]"')
    expect(http_log_secret.reload.request['params']).to eq('secret = "[FILTERED]"')
    expect(http_log_cookie.reload.request['headers']).to eq('Cookie: session_id=[FILTERED]; user_id=[FILTERED]')
    expect(http_log_query.reload.request['url']).to eq('https://example.com/api?access_token=[FILTERED]&other=param')
    expect(http_log_clean.reload.request['body']).to eq('no secrets here')
  end
end
