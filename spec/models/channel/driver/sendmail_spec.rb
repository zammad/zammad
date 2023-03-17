# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::Sendmail do
  context 'with env var ZAMMAD_MAIL_TO_FILE present' do

    let(:address) { Faker::Internet.email }
    let(:body)    { Faker::Lorem.sentence(word_count: 3) }
    let(:file)    { Rails.root.join("tmp/mails/#{address}.eml") }

    around do |example|
      ENV['ZAMMAD_MAIL_TO_FILE'] = '1'
      FileUtils.rm_f(file)
      example.run
      FileUtils.rm_f(file)
      ENV.delete('ZAMMAD_MAIL_TO_FILE')
    end

    it 'creates mail file', :aggregate_failures do
      described_class.new.send({}, { to: address, from: address, body: body })
      expect(file).to exist
      content = File.read(file)
      expect(content).to match(%r{#{body}})
      expect(content).to match(%r{#{address}})
    end
  end
end
