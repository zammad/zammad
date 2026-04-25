# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Rack::Middleware::SecureContext do
  let(:app)   { double('app') } # rubocop:disable RSpec/VerifiedDoubles
  let(:input) { { 'test' => 123 } }

  before do
    Setting.set('http_type', http_type)
    allow(app).to receive(:call)
  end

  context 'when HTTPS' do
    let(:http_type) { 'https' }

    it 'marks the environment as HTTPS' do
      described_class.new(app).call(input)

      expect(app).to have_received(:call).with(
        {
          'test'                => 123,
          'action_dispatch.ssl' => true
        }
      )
    end
  end

  context 'when not HTTPS' do
    let(:http_type) { 'http' }

    it 'does not mark the environment as HTTPS' do
      described_class.new(app).call(input)

      expect(app).to have_received(:call).with(
        {
          'test' => 123,
        }
      )
    end
  end

end
