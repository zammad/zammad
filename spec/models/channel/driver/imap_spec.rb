require 'rails_helper'

RSpec.describe Channel::Driver::Imap do
  # https://github.com/zammad/zammad/issues/2964
  context 'when connecting with a ASCII 8-Bit password' do
    it 'succeeds' do

      required_envs = %w[IMAP_ASCII_8BIT_HOST IMAP_ASCII_8BIT_USER IMAP_ASCII_8BIT_PASSWORD]
      required_envs.each do |key|
        next if ENV[key].present?

        skip("Need ENVs #{required_envs.join(', ')}.")
      end

      params = {
        host:     ENV['IMAP_ASCII_8BIT_HOST'],
        user:     ENV['IMAP_ASCII_8BIT_USER'],
        password: ENV['IMAP_ASCII_8BIT_PASSWORD'],
      }

      result = described_class.new.fetch(params, nil, 'check')

      expect(result.dig(:result)).to eq 'ok'
    end
  end
end
