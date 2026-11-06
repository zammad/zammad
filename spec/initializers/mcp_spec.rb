# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'MCP exception reporter' do # rubocop:disable RSpec/DescribeClass
  let(:reporter) { MCP.configuration.exception_reporter }

  before { allow(Rails.logger).to receive(:error) }

  it 'logs the exception behind an internal error, quoting its message' do
    failure = MCP::Server::RequestHandlerError.new('Internal error calling tool echo', nil, error_type: :internal_error, original_error: RuntimeError.new("broken\nline"))

    reporter.call(failure, {})

    expect(Rails.logger).to have_received(:error).with('MCP server: RuntimeError: "broken\\nline"')
  end

  it 'does not log a mistake of the client, whose text it is' do
    reporter.call(MCP::Server::RequestHandlerError.new("Tool not found: fake\nline", nil, error_type: :invalid_params), {})

    expect(Rails.logger).not_to have_received(:error)
  end

  it 'logs an exception of the transport' do
    reporter.call(ArgumentError.new('bad Accept header'), {})

    expect(Rails.logger).to have_received(:error).with('MCP server: ArgumentError: "bad Accept header"')
  end
end
