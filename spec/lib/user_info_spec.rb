# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UserInfo do

  describe '#current_user_id' do

    it 'is nil by default' do
      expect(described_class.current_user_id).to be_nil
    end

    it 'takes a User ID as paramter and returns it' do
      test_id = 99
      described_class.current_user_id = test_id
      expect(described_class.current_user_id).to eq(test_id)
    end
  end

  describe '#current_user' do

    it 'is nil by default' do
      expect(described_class.current_user).to be_nil
    end

    # Callers like Group::Assets#authorized_asset? ask for this once per record, so a lookup of
    #   "no user" must not cost a query per record.
    it 'does not query the database when no user is set' do
      queries = []
      subscription = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        queries.push(payload[:sql]) if payload[:name].to_s == 'User Load'
      end

      described_class.current_user

      expect(queries).to be_empty
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription)
    end

    it 'returns the set user' do
      user = create(:agent)
      described_class.current_user_id = user.id

      expect(described_class.current_user).to eq(user)
    end
  end

  describe '#ensure_current_user_id' do

    let(:return_value) { 'Hello World' }

    it 'uses and keeps set User IDs' do
      test_id = 99
      described_class.current_user_id = test_id

      described_class.ensure_current_user_id do
        expect(described_class.current_user_id).to eq(test_id)
      end

      expect(described_class.current_user_id).to eq(test_id)
    end

    it 'sets and resets temporary User ID 1' do
      described_class.current_user_id = nil

      described_class.ensure_current_user_id do
        expect(described_class.current_user_id).to eq(1)
      end

      expect(described_class.current_user_id).to be_nil
    end

    it 'resets current_user_id in case of an exception' do
      begin
        described_class.ensure_current_user_id do
          raise 'error'
        end
      rescue # rubocop:disable Lint/SuppressedException
      end

      expect(described_class.current_user_id).to be_nil
    end

    it 'passes return value of given block' do

      received = described_class.ensure_current_user_id do
        return_value
      end

      expect(received).to eq(return_value)
    end

  end

  describe '#reset' do

    it 'clears the current user id' do
      described_class.current_user_id = 99

      expect { described_class.reset }.to change(described_class, :current_user_id).to(nil)
    end

    it 'clears the current token' do
      described_class.current_token = create(:token)

      expect { described_class.reset }.to change(described_class, :current_token).to(nil)
    end

    it 'clears the current ip' do
      described_class.current_ip = '192.0.2.42'

      expect { described_class.reset }.to change(described_class, :current_ip).to(nil)
    end

    it 'rebuilds the assets without a user' do
      described_class.current_user_id = 99
      described_class.reset

      expect(described_class.assets.current_user_id).to be_nil
    end
  end

  describe 'with_user_id' do

    let(:return_value) { 'Hello World' }
    let(:test_id)         { 666 }
    let(:another_test_id) { 123 }

    it 'uses given user ID in the given block' do
      described_class.with_user_id(test_id) do
        expect(described_class.current_user_id).to eq(test_id)
      end
    end

    it 'resets to surrounding user ID' do
      described_class.current_user_id = test_id

      described_class.with_user_id(another_test_id) do
        expect(described_class.current_user_id).not_to eq(test_id)
      end

      expect(described_class.current_user_id).to eq(test_id)
    end

    it 'resets current_user_id in case of an exception' do
      begin
        described_class.with_user_id(test_id) do
          raise 'error'
        end
      rescue # rubocop:disable Lint/SuppressedException
      end

      expect(described_class.current_user_id).to be_nil
    end

    it 'passes return value of given block' do
      received = described_class.with_user_id(test_id) do
        return_value
      end

      expect(received).to eq(return_value)
    end

  end

  describe '#assets' do

    it 'is unprivileged without any user context', :aggregate_failures do
      described_class.reset

      expect(described_class.assets.agent?).to be(false)
      expect(described_class.assets.admin?).to be(false)
    end

    it 'is privileged in a system context', :aggregate_failures do
      described_class.reset

      described_class.with_system_context do
        expect(described_class.assets.agent?).to be(true)
        expect(described_class.assets.admin?).to be(true)
      end
    end

    it 'survives a reset, it marks the unit of work and not the user' do
      described_class.with_system_context do
        described_class.reset

        expect(described_class).to be_system_context
      end
    end

    it 'is present even if the context was never established' do
      Thread.current[:assets] = nil

      expect(described_class.assets).to be_present
    end
  end

  describe '#with_system_context' do

    let(:return_value) { 'Hello World' }

    it 'is not a system context by default' do
      expect(described_class).not_to be_system_context
    end

    it 'marks the given block as system context' do
      described_class.with_system_context do
        expect(described_class).to be_system_context
      end
    end

    it 'restores the surrounding state' do
      described_class.with_system_context do # rubocop:disable Lint/EmptyBlock
      end

      expect(described_class).not_to be_system_context
    end

    it 'restores the surrounding state in case of an exception' do
      begin
        described_class.with_system_context do
          raise 'error'
        end
      rescue # rubocop:disable Lint/SuppressedException
      end

      expect(described_class).not_to be_system_context
    end

    it 'passes return value of given block' do
      received = described_class.with_system_context do
        return_value
      end

      expect(received).to eq(return_value)
    end
  end

  describe '#with_assets_level' do

    let(:return_value) { 'Hello World' }
    let(:level)        { UserInfo::Assets::LEVEL_CUSTOMER }

    it 'uses given level in the given block' do
      described_class.with_assets_level(level) do
        expect(described_class.assets).to have_attributes(level: level, user: nil, current_user_id: nil)
      end
    end

    it 'applies the level to the asset checks' do
      described_class.with_assets_level(level) do
        expect(described_class.assets).to have_attributes(customer?: true, agent?: false, admin?: false)
      end
    end

    # The whole point for a job, which always runs in a system context.
    it 'keeps the level inside a system context' do
      described_class.with_system_context do
        described_class.with_assets_level(level) do
          expect(described_class.assets).not_to be_agent
        end
      end
    end

    it 'resets to the surrounding assets' do
      described_class.current_user_id = 666
      surrounding = described_class.assets

      described_class.with_assets_level(level) do
        expect(described_class.assets).not_to eq(surrounding)
      end

      expect(described_class.assets).to eq(surrounding)
    end

    it 'resets the assets in case of an exception' do
      surrounding = described_class.assets

      begin
        described_class.with_assets_level(level) do
          raise 'error'
        end
      rescue # rubocop:disable Lint/SuppressedException
      end

      expect(described_class.assets).to eq(surrounding)
    end

    it 'passes return value of given block' do
      received = described_class.with_assets_level(level) do
        return_value
      end

      expect(received).to eq(return_value)
    end

    it 'leaves the current user unset, so per-user asset checks stay untouched' do
      described_class.with_assets_level(level) do
        expect(described_class.current_user_id).to be_nil
      end
    end

    it 'refuses a blank level, which would fall back to the surrounding context' do
      expect { described_class.with_assets_level(nil) { nil } }.to raise_error(ArgumentError)
    end

    # The refusal must not cost the caller its context: it never switched away from it.
    it 'keeps the surrounding assets when it refuses a blank level' do
      described_class.current_user_id = 666
      surrounding = described_class.assets

      begin
        described_class.with_assets_level(nil) { nil }
      rescue ArgumentError # rubocop:disable Lint/SuppressedException
      end

      expect(described_class.assets).to eq(surrounding)
    end
  end

end
