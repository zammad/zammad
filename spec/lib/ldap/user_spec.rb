require 'rails_helper'
# rails autoloading issue
require 'ldap'
require 'ldap/user'

RSpec.describe Ldap::User do

  context '.uid_attribute' do

    it 'responds to .uid_attribute' do
      expect(described_class).to respond_to(:uid_attribute)
    end

    it 'returns uid attribute string from given attribute strucutre' do
      attributes = {
        samaccountname: 'TEST',
        custom:         'value',
      }
      expect(described_class.uid_attribute(attributes)).to eq('samaccountname')
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
  let(:mocked_ldap) { double() }

  context 'initialization config parameters' do

    it 'reuses given Ldap instance if given' do
      expect(Ldap).not_to receive(:new)
      instance = described_class.new(ldap: mocked_ldap)
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

      uid_attribute = 'samaccountname'
      config = {
        uid_attribute: uid_attribute
      }

      instance = described_class.new(config, ldap: mocked_ldap)

      expect(instance.uid_attribute).to eq(uid_attribute)
    end

    it 'creates own Ldap instance if none given' do
      expect(Ldap).to receive(:new)
      expect(described_class.new())
    end
  end

  context 'instance methods' do

    let(:initialization_config) {
      {
        uid_attribute: 'samaccountname',
        filter:        '(objectClass=user)',
      }
    }

    let(:instance) {
      described_class.new(initialization_config, ldap: mocked_ldap)
    }

    context '#valid?' do

      it 'responds to #valid?' do
        expect(instance).to respond_to(:valid?)
      end

      it 'validates username and password' do
        connection = double()
        expect(mocked_ldap).to receive(:connection).and_return(connection)

        ldap_entry = build(:ldap_entry)

        expect(mocked_ldap).to receive(:base_dn)
        expect(connection).to receive(:bind_as).and_return(true)

        expect(instance.valid?('example_username', 'password')).to be true
      end

      it 'fails for invalid credentials' do
        connection = double()
        expect(mocked_ldap).to receive(:connection).and_return(connection)

        ldap_entry = build(:ldap_entry)

        expect(mocked_ldap).to receive(:base_dn)
        expect(connection).to receive(:bind_as).and_return(false)

        expect(instance.valid?('example_username', 'wrong_password')).to be false
      end
    end

    context '#attributes' do

      it 'responds to #attributes' do
        expect(instance).to respond_to(:attributes)
      end

      it 'lists user attributes with example values' do
        ldap_entry = build(:ldap_entry)

        # selectable attribute
        ldap_entry['mail'] = 'test@example.com'

        # blacklisted attribute
        ldap_entry['lastlogon'] = DateTime.current

        expect(mocked_ldap).to receive(:search).and_yield(ldap_entry)

        attributes = instance.attributes

        expected_attributes = {
          dn:   String,
          mail: String,
        }

        expect(attributes).to include(expected_attributes)
        expect(attributes).not_to include(:lastlogon)
      end
    end

    context '#filter' do

      let(:initialization_config) {
        {
          uid_attribute: 'samaccountname',
        }
      }

      it 'responds to #filter' do
        expect(instance).to respond_to(:filter)
      end

      it 'tries filters and returns first one with entries' do
        expect(mocked_ldap).to receive(:entries?).and_return(true)
        expect(instance.filter).to be_a(String)
      end

      it 'fails if no filter found entries' do
        allow(mocked_ldap).to receive(:entries?).and_return(false)
        expect(instance.filter).to be nil
      end
    end

    context '#uid_attribute' do

      let(:initialization_config) {
        {
          filter: '(objectClass=user)',
        }
      }

      it 'responds to #uid_attribute' do
        expect(instance).to respond_to(:uid_attribute)
      end

      it 'tries to find uid attribute in example attributes' do
        ldap_entry = build(:ldap_entry)

        # selectable attribute
        ldap_entry['samaccountname'] = 'test@example.com'

        expect(mocked_ldap).to receive(:search).and_yield(ldap_entry)

        expect(instance.uid_attribute).to be_a(String)
      end

      it 'fails if no uid attribute could be found' do
        expect(mocked_ldap).to receive(:search)
        expect(instance.uid_attribute).to be nil
      end
    end
  end
end
