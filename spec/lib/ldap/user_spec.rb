# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
# rails autoloading issue
require 'ldap'
require 'ldap/user'
require 'tcr/net/ldap'

RSpec.describe Ldap::User do

  let(:mocked_ldap) { double() }

  describe '.uid_attribute' do

    it 'responds to .uid_attribute' do
      expect(described_class).to respond_to(:uid_attribute)
    end

    it 'returns uid attribute string from given attribute strucutre' do
      attributes = {
        objectguid: 'TEST',
        custom:     'value',
      }
      expect(described_class.uid_attribute(attributes)).to eq('objectguid')
    end

    it 'returns nil if no attribute could be found' do
      attributes = {
        custom: 'value',
      }
      expect(described_class.uid_attribute(attributes)).to be nil
    end

  end

  # required as 'let' to perform test based
  # expectations and reuse it in 'let' instance
  # as additional parameter

  context 'initialization config parameters' do

    it 'reuses given Ldap instance if given' do
      expect(Ldap).not_to receive(:new)
      described_class.new(ldap: mocked_ldap)
    end

    it 'takes optional filter' do

      filter = '(objectClass=custom)'
      config = {
        filter: filter
      }

      instance = described_class.new(config, ldap: mocked_ldap)

      expect(instance.filter).to eq(filter)
    end

    it 'takes optional uid_attribute' do

      uid_attribute = 'objectguid'
      config = {
        uid_attribute: uid_attribute
      }

      instance = described_class.new(config, ldap: mocked_ldap)

      expect(instance.uid_attribute).to eq(uid_attribute)
    end

    it 'creates own Ldap instance if none given' do
      expect(Ldap).to receive(:new)

      described_class.new()
    end
  end

  context 'instance methods' do

    let(:initialization_config) do
      {
        uid_attribute: 'objectguid',
        filter:        '(objectClass=user)',
      }
    end

    let(:instance) do
      described_class.new(initialization_config, ldap: mocked_ldap)
    end

    describe '#valid?' do

      it 'responds to #valid?' do
        expect(instance).to respond_to(:valid?)
      end

      it 'validates username and password' do
        connection = double()
        allow(mocked_ldap).to receive(:connection).and_return(connection)

        build(:ldap_entry)

        allow(mocked_ldap).to receive(:base_dn)
        allow(connection).to receive(:bind_as).and_return(true)

        expect(instance.valid?('example_username', 'password')).to be true
      end

      it 'fails for invalid credentials' do
        connection = double()
        allow(mocked_ldap).to receive(:connection).and_return(connection)

        build(:ldap_entry)

        allow(mocked_ldap).to receive(:base_dn)
        allow(connection).to receive(:bind_as).and_return(false)

        expect(instance.valid?('example_username', 'wrong_password')).to be false
      end
    end

    describe '#attributes' do

      it 'responds to #attributes' do
        expect(instance).to respond_to(:attributes)
      end

      it 'lists user attributes with example values' do
        ldap_entry = build(:ldap_entry)

        # selectable attribute
        ldap_entry['mail'] = 'test@example.com'

        # blacklisted attribute
        ldap_entry['lastlogon'] = DateTime.current

        allow(mocked_ldap).to receive(:search).and_yield(ldap_entry)

        attributes = instance.attributes

        expected_attributes = {
          dn:   String,
          mail: String,
        }

        expect(attributes).to include(expected_attributes)
        expect(attributes).not_to include(:lastlogon)
      end
    end

    describe '#filter' do

      let(:initialization_config) do
        {
          uid_attribute: 'objectguid',
        }
      end

      it 'responds to #filter' do
        expect(instance).to respond_to(:filter)
      end

      it 'tries filters and returns first one with entries' do
        allow(mocked_ldap).to receive(:entries?).and_return(true)
        expect(instance.filter).to be_a(String)
      end

      it 'fails if no filter found entries' do
        allow(mocked_ldap).to receive(:entries?).and_return(false)
        expect(instance.filter).to be nil
      end
    end

    describe '#uid_attribute' do

      let(:initialization_config) do
        {
          filter: '(objectClass=user)',
        }
      end

      it 'responds to #uid_attribute' do
        expect(instance).to respond_to(:uid_attribute)
      end

      it 'tries to find uid attribute in example attributes' do
        ldap_entry = build(:ldap_entry)

        # selectable attribute
        ldap_entry['objectguid'] = 'f742b361-32c6-4a92-baaa-eaae7df657ee'

        allow(mocked_ldap).to receive(:search).and_yield(ldap_entry)

        expect(instance.uid_attribute).to be_a(String)
      end

      it 'fails if no uid attribute could be found' do
        expect(mocked_ldap).to receive(:search)
        expect(instance.uid_attribute).to be nil
      end
    end
  end

  # Each of these test cases depends on
  # sample TCP transmission data recorded with TCR,
  # stored in test/data/tcr_cassettes.
  context 'on mocked LDAP connections' do
    around do |example|
      cassette_name = example.description.gsub(%r{[^0-9A-Za-z.\-]+}, '_')

      begin
        original_tcr_format = TCR.configuration.format
        TCR.configuration.format = 'marshal'
        TCR.use_cassette("lib/ldap/user/#{cassette_name}") { example.run }
      ensure
        TCR.configuration.format = original_tcr_format
      end
    end

    describe '#attributes' do
      let(:subject) { described_class.new(config, ldap: ldap) }
      let(:ldap)    { Ldap.new(config) }
      let(:config) do
        { 'host_url'  => 'ldap://localhost',
          'options'   => { 'dc=example,dc=org' => 'dc=example,dc=org' },
          'option'    => 'dc=example,dc=org',
          'base_dn'   => 'dc=example,dc=org',
          'bind_user' => 'cn=admin,dc=example,dc=org',
          'bind_pw'   => 'admin' }.with_indifferent_access
      end

      # see https://github.com/zammad/zammad/issues/2140
      #
      # This method grabs sample values of user attributes on the LDAP server.
      # It used to coerce ALL values to Unicode strings, including binary attributes
      # (e.g., usersmimecertificate / msexchmailboxsecuritydescriptor),
      # which led to valid Unicode gibberish (e.g., "\u0001\u0001\u0004...")
      #
      # When saving these values to the database,
      # ActiveRecord::Store would convert them to binary (ASCII-8BIT) strings,
      # which would then break #to_json with an Encoding::UndefinedConversion error.
      it 'skips binary attributes (#2140)' do
        Setting.set('ldap_config', subject.attributes)

        expect { Setting.get('ldap_config').to_json }
          .not_to raise_error
      end
    end
  end
end
