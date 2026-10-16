# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HttpLogTokenHeaderCleanup, :aggregate_failures, type: :db_migration do
  def create_http_log(data = {})
    HttpLog.without_callback(:save, :before, :filter_sensitive_data) do
      http_log = HttpLog.new(attributes_for(:http_log).merge(data))
      http_log.save!

      http_log
    end
  end

  let!(:http_log_request_token) do
    create_http_log(request: { content: "accept: */*\nprivate-token: s3cr3t\n" })
  end

  let!(:http_log_response_token) do
    create_http_log(response: { content: "x-auth-token: s3cr3t\n" })
  end

  let!(:http_log_without_token) { create_http_log(request: { content: "accept: */*\n" }) }

  it 'masks token headers in http logs' do
    migrate

    expect(http_log_request_token.reload.request['content']).to eq("accept: */*\nprivate-token: [FILTERED]\n")
    expect(http_log_response_token.reload.response['content']).to eq("x-auth-token: [FILTERED]\n")
    expect(http_log_without_token.reload.request['content']).to eq("accept: */*\n")
  end
end
