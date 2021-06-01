# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ldap do

  context 'initialization config parameters' do

    # required as 'let' to perform test based
    # expectations and reuse it in mock_initialization
    # as return param of Net::LDAP.new
    let(:mocked_ldap) { double(bind: true) }

    def mock_initialization(given:, expected:)
      allow(Net::LDAP).to receive(:new).with(expected).and_return(mocked_ldap)
      described_class.new(given)
    end

    it 'uses explicit host and port' do

      config = {
        host: 'localhost',
        port: 1337,
      }

      mock_initialization(
        given:    config,
        expected: config,
      )
    end

    context 'bind credentials' do

      it 'uses given credentials' do

        config = {
          host:      'localhost',
          port:      1337,
          bind_user: 'JohnDoe',
          bind_pw:   'zammad',
        }

        params = {
          host: 'localhost',
          port: 1337,
        }

        allow(mocked_ldap).to receive(:auth).with(config[:bind_user], config[:bind_pw])

        mock_initialization(
          given:    config,
          expected: params,
        )
      end

      it 'requires bind_user' do

        config = {
          host:    'localhost',
          port:    1337,
          bind_pw: 'zammad',
        }

        params = {
          host: 'localhost',
          port: 1337,
        }

        allow(mocked_ldap).to receive(:auth)

        mock_initialization(
          given:    config,
          expected: params,
        )
        expect(mocked_ldap).not_to have_received(:auth).with(config[:bind_user], config[:bind_pw])
      end

      it 'requires bind_pw' do

        config = {
          host:      'localhost',
          port:      1337,
          bind_user: 'JohnDoe',
        }

        params = {
          host: 'localhost',
          port: 1337,
        }

        allow(mocked_ldap).to receive(:auth)

        mock_initialization(
          given:    config,
          expected: params,
        )
        expect(mocked_ldap).not_to have_received(:auth).with(config[:bind_user], config[:bind_pw])
      end
    end

    it 'extracts port from host' do

      config = {
        host: 'localhost:1337'
      }

      params = {
        host: 'localhost',
        port: 1337,
      }

      mock_initialization(
        given:    config,
        expected: params,
      )
    end

    context 'host_url' do
      it 'parses protocol and host' do
        config = {
          host_url: 'ldaps://localhost'
        }

        params = {
          host:       'localhost',
          port:       636,
          encryption: Hash
        }

        mock_initialization(
          given:    config,
          expected: params,
        )
      end

      it 'prefers parsing over explicit parameters' do
        config = {
          host:     'anotherhost',
          port:     7777,
          host_url: 'ldap://localhost:389'
        }

        params = {
          host: 'localhost',
          port: 389,
        }

        mock_initialization(
          given:    config,
          expected: params,
        )
      end
    end

    it 'falls back to default ldap port' do
      config = {
        host: 'localhost',
      }

      params = {
        host: 'localhost',
        port: 389,
      }

      mock_initialization(
        given:    config,
        expected: params,
      )
    end

    it 'uses explicit ssl' do

      config = {
        host: 'localhost',
        port: 1337,
        ssl:  true,
      }

      expected = {
        host:       'localhost',
        port:       1337,
        encryption: Hash,
      }

      mock_initialization(
        given:    config,
        expected: expected,
      )
    end

    it "uses 'ldap_config' Setting as fallback" do

      config = {
        host: 'localhost',
        port: 1337,
      }

      allow(Setting).to receive(:get)
      allow(Setting).to receive(:get).with('ldap_config').and_return(config)

      mock_initialization(
        given:    nil,
        expected: config,
      )
    end
  end

  context 'instance methods' do

    # required as 'let' to perform test based
    # expectations and reuse it in 'let' instance
    # as return param of Net::LDAP.new
    let(:mocked_ldap) { double(bind: true) }
    let(:instance) do
      allow(Net::LDAP).to receive(:new).and_return(mocked_ldap)
      described_class.new(
        host: 'localhost',
        port: 1337,
      )
    end

    describe '#preferences' do

      it 'responds to #preferences' do
        expect(instance).to respond_to(:preferences)
      end

      it 'returns preferences' do
        attributes = {
          namingcontexts: ['ou=dep1,ou=org', 'ou=dep2,ou=org']
        }
        allow(mocked_ldap).to receive(:search_root_dse).and_return(attributes)

        expect(instance.preferences).to eq(attributes)
      end
    end

    describe '#search' do

      let(:base) { 'DC=domain,DC=tld' }
      let(:filter) { '(objectClass=user)' }

      it 'responds to #search' do
        expect(instance).to respond_to(:search)
      end

      it 'performs search for a filter, base and scope and yields of returned entries' do

        scope = Net::LDAP::SearchScope_BaseObject

        additional = {
          base:  base,
          scope: scope,
        }

        expected = {
          filter: filter,
          base:   base,
          scope:  scope,
        }

        yield_entry = build(:ldap_entry)
        allow(mocked_ldap).to receive(:search).with(include(expected)).and_yield(yield_entry).and_return(true)

        check_entry = nil
        instance.search(filter, additional) { |entry| check_entry = entry }
        expect(check_entry).to eq(yield_entry)
      end

      it 'falls back to whole subtree scope search' do

        additional = {
          base: base,
        }

        expected = {
          filter: filter,
          base:   base,
          scope:  Net::LDAP::SearchScope_WholeSubtree,
        }

        yield_entry = build(:ldap_entry)
        allow(mocked_ldap).to receive(:search).with(include(expected)).and_yield(yield_entry).and_return(true)

        check_entry = nil
        instance.search(filter, additional) { |entry| check_entry = entry }
        expect(check_entry).to eq(yield_entry)
      end

      it 'falls back to base_dn configuration parameter' do

        expected = {
          filter: filter,
          base:   base,
          scope:  Net::LDAP::SearchScope_WholeSubtree,
        }

        allow(Net::LDAP).to receive(:new).and_return(mocked_ldap)
        instance = described_class.new(
          host:    'localhost',
          port:    1337,
          base_dn: base,
        )

        yield_entry = build(:ldap_entry)
        allow(mocked_ldap).to receive(:search).with(include(expected)).and_yield(yield_entry).and_return(true)

        check_entry = nil
        instance.search(filter) { |entry| check_entry = entry }
        expect(check_entry).to eq(yield_entry)
      end
    end

    describe '#entries?' do

      let(:filter) { '(objectClass=user)' }

      it 'responds to #entries?' do
        expect(instance).to respond_to(:entries?)
      end

      it 'returns true if entries are present' do
        params = {
          filter: filter
        }
        allow(mocked_ldap).to receive(:search).with(include(params)).and_yield(build(:ldap_entry)).and_return(nil)

        expect(instance.entries?(filter)).to be true
      end

      it 'returns false if no entries are present' do
        params = {
          filter: filter
        }
        allow(mocked_ldap).to receive(:search).with(include(params)).and_return(true)

        expect(instance.entries?(filter)).to be false
      end

    end
  end
end
