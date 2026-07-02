# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HttpLogBearerTokenCleanup, :aggregate_failures, type: :db_migration do
  def create_http_log(data = {})
    HttpLog.without_callback(:save, :before, :filter_sensitive_data) do
      http_log = HttpLog.new(attributes_for(:http_log).merge(data))
      http_log.save!

      http_log
    end
  end

  let(:dot_separated_bearer_token) do
    %w[
      eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9
      eyJzdWIiOiJ1c2VyQGV4YW1wbGUuY29tIiwicm9sZSI6ImFwcCJ9
      c2lnbmF0dXJl
    ].join('.')
  end

  let!(:http_log_bearer) do
    create_http_log(request: { headers: "authorization: Bearer #{dot_separated_bearer_token}" })
  end

  let!(:http_log_partially_filtered_bearer) do
    create_http_log(
      request: {
        headers: [
          'Authorization: Bearer [FILTERED]',
          'eyJzdWIiOiJ1c2VyQGV4YW1wbGUuY29tIn0',
          'c2lnbmF0dXJl',
        ].join('.'),
      }
    )
  end

  let!(:http_log_response_bearer) do
    create_http_log(response: { headers: "Authorization: Bearer #{dot_separated_bearer_token}" })
  end

  let!(:http_log_without_bearer) { create_http_log(request: { body: 'no secrets here' }) }

  it 'masks bearer authorization tokens in http logs' do
    migrate

    expect(http_log_bearer.reload.request['headers']).to eq('Authorization: Bearer [FILTERED]')
    expect(http_log_partially_filtered_bearer.reload.request['headers']).to eq('Authorization: Bearer [FILTERED]')
    expect(http_log_response_bearer.reload.response['headers']).to eq('Authorization: Bearer [FILTERED]')
    expect(http_log_without_bearer.reload.request['body']).to eq('no secrets here')
  end
end
