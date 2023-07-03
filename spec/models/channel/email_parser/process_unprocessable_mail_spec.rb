# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser#process_unprocessable_mail', aggregate_failures: true, type: :model do

  context 'when receiving unprocessable mail' do
    let(:mail) do
      <<~MAIL
        From: ME Bob <me@example.com>
        To: customer@example.com
        Subject: some subject

        Some Text
      MAIL
    end
    let(:dir) { Channel::EmailParser::UNPROCESSABLE_MAIL_DIRECTORY }

    before do
      FileUtils.rm_r(dir) if dir.exist?
      parser = Channel::EmailParser.new
      allow(parser).to receive(:_process).and_raise(Timeout::Error)
      begin
        parser.process({}, mail)
      rescue RuntimeError
        # expected
      end
    end

    after do
      FileUtils.rm_r(dir) if dir.exist?
    end

    it 'saves the unprocessable email into a file' do
      expect(dir.join('ce61e7319bcc4297c1d7dfea2fbc87dd.eml')).to exist
    end

    it 'allows reprocessing of the stored email' do
      expect { Channel::EmailParser.process_unprocessable_mails }.to change(Ticket, :count).by(1)
      expect(dir.join('ce61e7319bcc4297c1d7dfea2fbc87dd.eml')).not_to exist
    end
  end
end
