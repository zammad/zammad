# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Calendar::Ical::Fetch do
  subject(:execute) { described_class.execute(url:) }

  let(:url)  { 'http://test/calendar1.ics' }
  let(:body) { Rails.root.join('test/data/calendar/calendar1.ics').read }

  before do
    allow(HostnameSafetyCheck).to receive(:validate!).and_return('1.2.3.4')
    stub_request(:get, url).to_return(body:)
  end

  it 'returns the feed body' do
    expect(execute).to eq(body)
  end

  # a calendar feed may well live on an intranet host
  it 'allows private addresses' do
    allow(UserAgent).to receive(:get).and_call_original

    execute

    expect(UserAgent).to have_received(:get).with(url, {}, { validate_safety: { allow_private: true } })
  end

  it 'raises the error of an unsuccessful response' do
    result = instance_double(UserAgent::Result, success?: false, error: 'No such file http://test/calendar1.ics, 404!')
    allow(UserAgent).to receive(:get).and_return(result)

    expect { execute }.to raise_error(%r{No such file})
  end

  it 'raises an unsafe hostname out of the service' do
    allow(HostnameSafetyCheck).to receive(:validate!).and_raise(
      HostnameSafetyCheck::LoopbackIpError.new('127.0.0.1')
    )

    expect { execute }.to raise_error(HostnameSafetyCheck::LoopbackIpError)
  end
end
