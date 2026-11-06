# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Rack::Middleware::MCPBodyLimit, :aggregate_failures do
  let(:app)  { ->(env) { [200, {}, [env['rack.input'].read, env[described_class::TOO_LARGE].inspect]] } }
  let(:body) { 'x' * 10 }

  before { stub_const("#{described_class}::LIMIT", 10) }

  def call(path: '/mcp', input: body, **env)
    described_class.new(app).call(Rack::MockRequest.env_for(path, method: 'POST', input:).merge(env))
  end

  it 'passes a body within the limit on' do
    expect(call.last).to eq([body, 'nil'])
  end

  it 'flags a body whose length is announced too large without reading it' do
    input = StringIO.new(body)

    expect(call(input:, 'CONTENT_LENGTH' => '11').last).to eq(['', 'true'])
    expect(input.pos).to eq(0)
  end

  it 'replaces a larger body whose length is not announced by an empty one, reading no more than one byte past the limit' do
    input = StringIO.new('x' * 100)

    expect(call(input:, 'CONTENT_LENGTH' => nil).last).to eq(['', 'true'])
    expect(input.pos).to eq(11)
  end

  it 'flags a larger body whose announced length is too small' do
    expect(call(input: 'x' * 100, 'CONTENT_LENGTH' => '5').last).to eq(['', 'true'])
  end

  it 'limits the body on the paths the router normalizes to /mcp' do
    %w[/mcp/ //mcp].each do |path|
      expect(call(input: 'x' * 100, 'PATH_INFO' => path).last).to eq(['', 'true'])
    end
  end

  it 'leaves other paths alone' do
    expect(call(path: '/api/v1/tickets', input: 'x' * 100).last).to eq(['x' * 100, 'nil'])
  end
end
