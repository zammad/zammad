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
  end
end
