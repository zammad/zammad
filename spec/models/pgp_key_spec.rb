# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe PGPKey, type: :model do
  let(:user) { create(:admin) }

  describe '#create' do
    let(:fixture)     { 'zammad@localhost' }
    let(:key)         { Rails.root.join("spec/fixtures/files/pgp/#{fixture}.asc").read }
    let(:fingerprint) { Rails.root.join("spec/fixtures/files/pgp/#{fixture}.fingerprint").read }
    let(:created_at)  { DateTime.parse(Rails.root.join("spec/fixtures/files/pgp/#{fixture}.created_at").read) }
    let(:expires_at)  { DateTime.parse(Rails.root.join("spec/fixtures/files/pgp/#{fixture}.expires_at").read) }
    let(:passphrase)  { Rails.root.join("spec/fixtures/files/pgp/#{fixture}.passphrase").read }

    let(:params) do
      {
        key:           key,
        passphrase:    passphrase,
        created_by_id: user.id,
        updated_by_id: user.id,
      }
    end

    shared_examples 'saving the record' do
      it 'saves the record' do
        expect(described_class.create!(params)).to have_attributes(
          name:            fixture,
          fingerprint:     fingerprint,
          created_at:      created_at,
          expires_at:      expires_at,
          email_addresses: [fixture],
          secret:          true,
        )
      end

      it 'prevents duplicate imports' do
        expect { 2.times { described_class.create!(params) } }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it_behaves_like 'saving the record'

    context 'with a wrong passphrase' do
      let(:passphrase) { 'foobar' }

      it 'raises an error' do
        expect { described_class.create!(params) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with active domain alias feature' do
      shared_examples 'saving the record with expected domain alias' do |expected|
        it "saves the record with expected domain alias: #{expected.inspect}" do
          expect(described_class.create!(extended_params)).to have_attributes(
            name:            fixture,
            fingerprint:     fingerprint,
            created_at:      created_at,
            expires_at:      expires_at,
            email_addresses: [fixture],
            secret:          true,
            domain_alias:    expected
          )
        end
      end

      let(:extended_params) do
        params.merge(domain_alias: 'zammad.org')
      end

      it_behaves_like 'saving the record with expected domain alias', '%@zammad.org'

      context 'without given domain alias' do
        let(:extended_params) do
          params.merge(domain_alias: nil)
        end

        it_behaves_like 'saving the record with expected domain alias', nil
      end

      context 'with an empty domain alias' do
        let(:extended_params) do
          params.merge(domain_alias: '')
        end

        it_behaves_like 'saving the record with expected domain alias', nil
      end
    end

    describe 'keyfile' do
      let(:key) { File.open(key_path) }

      context 'with a binary keyfile' do
        let(:key_path) { Rails.root.join('spec/fixtures/files/pgp/zammad@localhost.pgp') }

        it_behaves_like 'saving the record'
      end

      context 'with an invalid keyfile' do
        let(:key_path) { Rails.root.join('spec/fixtures/files/upload/hello_world.txt') }

        it 'raises an error' do
          expect { described_class.create!(params) }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end

  describe '#prepare_email_addresses' do
    let(:pgp_key) { create(:pgp_key) }

    before do
      pgp_key.update(name: name)
      pgp_key.prepare_email_addresses
    end

    shared_examples 'saving only email addresses' do |expected|
      it 'saves only email addresses' do
        expect(pgp_key.email_addresses).to eq(expected)
      end
    end

    context 'with single UID' do
      context 'with real name and email address' do
        let(:name) { 'Zammad Helpdesk <zammad@localhost>' }

        it_behaves_like 'saving only email addresses', ['zammad@localhost']
      end
    end

    context 'with multiple UIDs' do
      let(:name) { 'Multi PGP1 <multipgp1@example.com>, Multi PGP2 <multipgp2@example.com>' }

      it_behaves_like 'saving only email addresses', ['multipgp1@example.com', 'multipgp2@example.com']
    end
  end

  describe '#email_addresses' do
    let(:pgp_key) { create(:'pgp_key/zammad@localhost') }

    it 'returns correct email address' do
      expect(pgp_key.email_addresses).to eq(['zammad@localhost'])
    end

    context 'with multiple UIDs' do
      let(:pgp_key) { create(:'pgp_key/multipgp2@example.com') }

      it 'returns all associated email addresses' do
        expect(pgp_key.email_addresses).to eq(['multipgp1@example.com', 'multipgp2@example.com'])
      end
    end
  end

  describe '.for_recipient_email_addresses!', mariadb: true do
    let!(:pgp_key1) { create(:'pgp_key/pgp1@example.com') }
    let!(:pgp_key2) { create(:'pgp_key/pgp2@example.com') }
    let!(:pgp_key3) { create(:'pgp_key/pgp3@example.com') }

    context 'when all supplied addresses have corresponding keys available' do
      let(:addresses) { %w[pgp1@example.com pgp2@example.com pgp3@example.com] }

      it 'returns correct keys' do
        expect(described_class.for_recipient_email_addresses!(addresses)).to include(pgp_key1, pgp_key2, pgp_key3)
      end
    end

    context 'when one of supplied addresses does not have a corresponding key available' do
      let(:addresses) { %w[pgp1@example.com pgp2@example.com pgp3@example.com nonexistentkey@example.com] }

      it 'raises an error' do
        expect { described_class.for_recipient_email_addresses!(addresses) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when none of supplied addresses has a corresponding key available' do
      let(:addresses) { %w[nonexistentkey@example.com anothernonexistentkey@example.com] }

      it 'raises an error' do
        expect { described_class.for_recipient_email_addresses!(addresses) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with keys with multiple UIDs' do
      let!(:multipgp_key) { create(:'pgp_key/multipgp2@example.com') }
      let(:addresses)     { %w[pgp1@example.com pgp2@example.com pgp3@example.com multipgp1@example.com multipgp2@example.com] }

      it 'returns correct keys' do
        expect(described_class.for_recipient_email_addresses!(addresses)).to include(pgp_key1, pgp_key2, pgp_key3, multipgp_key)
      end
    end

    context 'with active domain alias feature' do
      before do
        Setting.set('pgp_recipient_alias_configuration', true)
      end

      let!(:pgp_key3) { create(:pgp_key, fixture: 'pgp3@example.com', domain_alias: 'domain3.com') }

      let(:addresses) { %w[pgp1@example.com pgp2@example.com example@domain3.com] }

      it 'returns correct keys' do
        expect(described_class.for_recipient_email_addresses!(addresses)).to include(pgp_key1, pgp_key2, pgp_key3)
      end
    end
  end

  describe '.find_by_uid', mariadb: true do
    let!(:pgp_key1) { create(:'pgp_key/pgp1@example.com') }

    context 'when an existing uid is used' do
      it 'returns the correct key' do
        expect(described_class.find_by_uid('pgp1@example.com')).to eq(pgp_key1) # rubocop:disable Rails/DynamicFindBy
      end
    end

    context 'when a non-existing uid is used' do
      it 'raises an error' do
        expect { described_class.find_by_uid('pgp123@example.com') }.to raise_error(ActiveRecord::RecordNotFound) # rubocop:disable Rails/DynamicFindBy
      end
    end

    context 'when a key with a similar uid is present' do
      before do
        create(:'pgp_key/noexpirepgp1@example.com')
      end

      it 'returns the correct key' do
        expect(described_class.find_by_uid('pgp1@example.com')).to eq(pgp_key1) # rubocop:disable Rails/DynamicFindBy
      end
    end

    context 'when recipient alias configuration is active' do
      before do
        Setting.set('pgp_recipient_alias_configuration', true)
      end

      context 'when there is no match for the domain' do
        it 'raises an error' do
          expect { described_class.find_by_uid('nicole.braun@zammad.org') }.to raise_error(ActiveRecord::RecordNotFound) # rubocop:disable Rails/DynamicFindBy
        end
      end

      context 'when there is at least one match for the domain' do
        let!(:pgp_key1) { create(:'pgp_key/pgp1@example.com', domain_alias: 'zammad.org') }

        it 'returns the correct key' do
          expect(described_class.find_by_uid('nicole.braun@zammad.org')).to eq(pgp_key1) # rubocop:disable Rails/DynamicFindBy
        end
      end
    end
  end

  describe '.find_all_by_uid', mariadb: true do
    let!(:pgp_key1) { create(:'pgp_key/pgp1@example.com', domain_alias: 'zammad.org') }
    let!(:pgp_key2) { create(:'pgp_key/pgp2@example.com', domain_alias: 'zammad.org') }
    let!(:pgp_key3) { create(:'pgp_key/pgp3@example.com', domain_alias: 'zammad.org') }

    context 'when there is no match for the uid' do
      it 'returns an empty array' do
        expect(described_class.find_all_by_uid('nicole.braun@zammad.org')).to eq([])
      end
    end

    context 'when recipient alias configuration is active' do
      before do
        Setting.set('pgp_recipient_alias_configuration', true)
      end

      context 'when there is no match for the uid' do
        it 'returns an empty array' do
          expect(described_class.find_all_by_uid('nicole.braun@zammad.com')).to eq([])
        end
      end

      context 'when there is at least one match for the uid' do
        it 'returns the correct keys' do
          expect(described_class.find_all_by_uid('pgp1@example.com')).to include(pgp_key1)
        end
      end

      context 'when there is more than one match for the uid (domain alias)' do
        it 'returns the correct keys' do
          expect(described_class.find_all_by_uid('nicole.braun@zammad.org')).to include(pgp_key1, pgp_key2, pgp_key3)
        end
      end
    end

    context 'when recipient alias configuration is inactive' do
      before do
        Setting.set('pgp_recipient_alias_configuration', false)
      end

      context 'when there is no match for the uid' do
        it 'returns an empty array' do
          expect(described_class.find_all_by_uid('nicole.braun@zammad.org')).to eq([])
        end
      end

      context 'when there is at least one match for the uid' do
        it 'returns the correct keys' do
          expect(described_class.find_all_by_uid('pgp1@example.com')).to include(pgp_key1)
        end
      end
    end
  end
end
