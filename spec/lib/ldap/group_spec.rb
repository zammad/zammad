# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
# rails autoloading issue
require 'ldap'
require 'ldap/group'

RSpec.describe Ldap::Group do

  # required as 'let' to perform test based
  # expectations and reuse it in 'let' instance
  # as additional parameter
  let(:mocked_ldap) { double() }

  describe '.uid_attribute' do

    it 'responds to .uid_attribute' do
      expect(described_class).to respond_to(:uid_attribute)
    end

    it 'returns uid attribute' do
      expect(described_class.uid_attribute).to be_a(String)
    end
  end

  context 'initialization config parameters' do

    it 'reuses given Ldap instance if given' do
      config = {}
      expect(Ldap).not_to receive(:new).with(config)
      described_class.new(config, ldap: mocked_ldap)
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

      uid_attribute = 'dn'
      config = {
        uid_attribute: uid_attribute
      }

      instance = described_class.new(config, ldap: mocked_ldap)

      expect(instance.uid_attribute).to eq(uid_attribute)
    end

    it 'creates own Ldap instance if none given' do
      expect(Ldap).to receive(:new)

      described_class.new
    end
  end

  context 'instance methods' do

    let(:initialization_config) do
      {
        uid_attribute: 'dn',
        filter:        '(objectClass=group)',
      }
    end

    let(:instance) do
      described_class.new(initialization_config, ldap: mocked_ldap)
    end

    describe '#list' do

      it 'responds to #list' do
        expect(instance).to respond_to(:list)
      end

      it 'returns a Hash of groups' do
        ldap_entry = build(:ldap_entry)
        allow(mocked_ldap).to receive(:search).and_return(ldap_entry)
        expect(instance.list).to be_a(Hash)
      end
    end

    describe '#filter' do

      let(:initialization_config) do
        {
          uid_attribute: 'dn',
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

      it 'responds to #uid_attribute' do
        expect(instance).to respond_to(:uid_attribute)
      end

      it 'returns the uid attribute' do
        expect(instance.uid_attribute).to be_a(String)
      end
    end
  end
end
