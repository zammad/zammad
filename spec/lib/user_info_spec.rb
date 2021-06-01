# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UserInfo do

  describe '#current_user_id' do

    it 'is nil by default' do
      expect(described_class.current_user_id).to be nil
    end

    it 'takes a User ID as paramter and returns it' do
      test_id = 99
      described_class.current_user_id = test_id
      expect(described_class.current_user_id).to eq(test_id)
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

      expect(described_class.current_user_id).to be nil
    end

    it 'resets current_user_id in case of an exception' do
      begin
        described_class.ensure_current_user_id do
          raise 'error'
        end
      rescue # rubocop:disable Lint/SuppressedException
      end

      expect(described_class.current_user_id).to be nil
    end

    it 'passes return value of given block' do

      received = described_class.ensure_current_user_id do
        return_value
      end

      expect(received).to eq(return_value)
    end

  end
end
