# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::ReplyToBasedSender, type: :channel_filter do
  describe '.run' do
    let(:mail_hash) { Channel::EmailParser.new.parse(<<~RAW.chomp) }
      From: daffy.duck@acme.corp
      To: batman@marvell.com
      Subject: Anvil
      Reply-To: #{reply_to}

      I can haz anvil!
    RAW

    before do
      Setting.set('postmaster_sender_based_on_reply_to', 'as_sender_of_email')
    end

    context 'when empty reply-to' do
      let(:reply_to) { '' }

      it 'keeps from' do
        expect { filter(mail_hash) }
          .not_to change { mail_hash[:from] }
      end
    end

    context 'when empty reply-to realname and invalid address' do
      let(:reply_to) { '<>' }

      it 'keeps from' do
        expect { filter(mail_hash) }
          .not_to change { mail_hash[:from] }
      end
    end

    context 'when valid reply-to address' do
      let(:reply_to) { '<bugs.bunny@acme.corp>' }

      it 'sets from to reply-to address' do
        expect { filter(mail_hash) }
          .to change { mail_hash[:from] }.to('bugs.bunny@acme.corp')
      end
    end

    context 'when valid reply-to realname and address' do
      let(:reply_to) { 'Bugs Bunny <bugs.bunny@acme.corp>' }

      it 'sets from to reply-to realname and address' do
        expect { filter(mail_hash) }
          .to change { mail_hash[:from] }.to('Bugs Bunny <bugs.bunny@acme.corp>')
      end
    end

    context 'when valid reply-to realname and invalid address' do
      let(:reply_to) { '"Bugs Bunny" <>' }

      it 'sets from to reply-to realname' do
        expect { filter(mail_hash) }
          .to change { mail_hash[:from] }.to('"Bugs Bunny"')
      end
    end

  end
end
