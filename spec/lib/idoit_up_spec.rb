# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe IdoitUp do
  let(:secret)    { 'shared-secret' }
  let(:endpoint)  { 'https://addon.example.com' }
  let(:idoit_url) { 'https://idoit-up.example.com' }
  let(:user)      { create(:agent, email: 'Agent@Example.com', firstname: 'Ann', lastname: 'Agent') }

  before do
    described_class.instance_variable_set(:@_cache, nil)
    allow(Setting).to receive(:get).and_call_original
    allow(Setting).to receive(:get).with('idoit_up_config').and_return(
      { api_token: secret, endpoint: endpoint, verify_ssl: false }
    )
  end

  def stub_bridge(responses)
    allow(described_class).to receive(:_rest_get) do |_connection, path|
      responses.fetch(path) { raise "unexpected bridge call #{path}" }
    end
  end

  describe '.verify' do
    it 'raises on missing configuration', :aggregate_failures do
      expect { described_class.verify('', endpoint, user: user) }
        .to raise_error(RuntimeError, %r{missing endpoint or api_token})
      expect { described_class.verify(secret, '', user: user) }
        .to raise_error(RuntimeError, %r{missing endpoint or api_token})
    end

    it 'returns the class list from the add-on' do
      stub_bridge('/classes' => { 'results' => [{ 'id' => 'C__OBJTYPE__SERVER', 'title' => 'Server' }] })

      expect(described_class.verify(secret, endpoint, user: user)['result'])
        .to eq([{ 'id' => 'C__OBJTYPE__SERVER', 'title' => 'Server' }])
    end
  end

  describe '.query' do
    it 'returns object types' do
      stub_bridge('/classes' => { 'results' => [{ 'id' => 'C__OBJTYPE__SERVER', 'title' => 'Server' }] })

      expect(described_class.query('cmdb.object_types', user: user)['result'].first['title']).to eq('Server')
    end

    it 'returns objects by id with SSO links into i-doit up' do
      stub_bridge(
        '/classes'         => { 'results' => [{ 'id' => 'C__OBJTYPE__SERVER', 'title' => 'Server' }] },
        '/config'          => { 'idoitUrl' => "#{idoit_url}/" },
        '/objects/abc-123' => {
          'id'             => 'abc-123',
          'title'          => 'webserver01',
          'status'         => 2,
          'classification' => { 'id' => 'C__OBJTYPE__SERVER', 'title' => 'Server' },
        },
      )

      expect(described_class.query('cmdb.objects', { ids: ['abc-123'] }, user: user)['result'].first).to include(
        'id'    => 'abc-123',
        'title' => 'webserver01',
        'link'  => "#{idoit_url}/connect?referer=%2Fobject%2Fabc-123&to=zammad",
      )
    end

    it 'searches and filters by class' do
      stub_bridge(
        '/classes'           => { 'results' => [] },
        '/config'            => { 'idoitUrl' => idoit_url },
        '/search?search=web' => { 'results' => [
          { 'id' => '1', 'title' => 'web1', 'class' => 'A' },
          { 'id' => '2', 'title' => 'web2', 'class' => 'B' },
        ] },
      )

      result = described_class.query('cmdb.objects', { title: '%web%', type: 'B' }, user: user)['result']
      expect(result.pluck('id')).to eq(['2'])
    end

    it 'raises on an unsupported method' do
      expect { described_class.query('unsupported.method', user: user) }
        .to raise_error(RuntimeError, %r{Unsupported i-doit up method})
    end
  end

  describe '._rest_get' do
    let(:connection) { { base: endpoint, secret: secret, verify_ssl: false, user: user } }

    it 'signs the call for the acting user', :aggregate_failures do
      allow(UserAgent).to receive(:get).and_return(instance_double(UserAgent::Result, success?: true, data: { 'ok' => true }))

      described_class._rest_get(connection, '/classes')

      expect(UserAgent).to have_received(:get) do |url, _params, options|
        expect(url).to eq("#{endpoint}/api/bridge/classes")
        token = options[:headers]['Authorization'].delete_prefix('Bearer ')
        claims = IdoitUp::Token.verify(token, audience: 'idoit-addon', secret: secret)
        expect(claims).to include('sub' => 'agent@example.com', 'name' => 'Ann Agent')
      end
    end

    it 'refuses without a user email' do
      expect { described_class._rest_get(connection.merge(user: nil), '/classes') }
        .to raise_error(RuntimeError, %r{requires a user with an email})
    end
  end

  describe IdoitUp::Token do
    it 'round-trips and rejects tampering', :aggregate_failures do
      token = described_class.sign({ sub: 'a@b.c' }, audience: 'x', secret: secret)
      expect(described_class.verify(token, audience: 'x', secret: secret)['sub']).to eq('a@b.c')
      expect { described_class.verify(token, audience: 'y', secret: secret) }.to raise_error(described_class::Error, %r{audience})
      expect { described_class.verify(token, audience: 'x', secret: 'other') }.to raise_error(described_class::Error, %r{signature})
      expect { described_class.verify('a.b', audience: 'x', secret: secret) }.to raise_error(described_class::Error, %r{Malformed})
    end

    it 'rejects expired tokens' do
      token = described_class.sign({ sub: 'a@b.c' }, audience: 'x', ttl: -60, secret: secret)
      expect { described_class.verify(token, audience: 'x', secret: secret) }.to raise_error(described_class::Error, %r{expired})
    end
  end

  describe '._normalize_endpoint' do
    it 'strips trailing slash' do
      expect(described_class._normalize_endpoint('https://example.com/')).to eq('https://example.com')
    end

    it 'raises on non-http URL' do
      expect { described_class._normalize_endpoint('ftp://example.com') }
        .to raise_error(RuntimeError, %r{Invalid endpoint})
    end
  end

  describe '._status_label' do
    it { expect(described_class._status_label(2)).to eq('normal') }
    it { expect(described_class._status_label(3)).to eq('archived') }
    it { expect(described_class._status_label(4)).to eq('deleted') }
    it { expect(described_class._status_label(99)).to eq('unknown') }
  end
end
