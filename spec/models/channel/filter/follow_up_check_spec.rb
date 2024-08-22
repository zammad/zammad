# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::FollowUpCheck, type: :channel_filter do
  describe '.run' do
    before do
      Channel::EmailParser.new.process({}, <<~RAW.chomp)
        From: daffy.duck@example.com
        To: batman@example.com
        Subject: Question regarding A
        Message-ID: <abc@example.com>

        Help!
      RAW
    end

    let(:mail_subject) { 'RE: Question regarding A' }
    let(:mail_hash)    { Channel::EmailParser.new.parse(<<~RAW.chomp) }
      From: mike@example.com
      To: cat@example.com
      Subject: #{mail_subject}
      References: #{mail_references}

      Some nice text!
    RAW

    context 'with enabled advanced follow up detection' do

      context 'when references header is empty' do
        let(:mail_references) { '' }

        it 'keeps :x-zammad-ticket-id empty' do
          expect { filter(mail_hash) }
            .not_to change { mail_hash[:'x-zammad-ticket-id'] }
        end
      end

      context 'when references header contains message id of inital mail' do
        let(:mail_references) { '<12345@example.com> <abc@example.com>' }

        it 'set :x-zammad-ticket-id header' do
          expect { filter(mail_hash) }
            .to change { mail_hash[:'x-zammad-ticket-id'] }
        end
      end
    end

    context 'with disabled advanced follow up detection' do
      before do
        Setting.set('postmaster_follow_up_search_in', [])
      end

      context 'when references header contains message id of inital mail' do
        let(:mail_references) { '<12345@example.com> <abc@example.com>' }

        it 'keeps :x-zammad-ticket-id empty' do
          expect { filter(mail_hash) }
            .not_to change { mail_hash[:'x-zammad-ticket-id'] }
        end
      end
    end

  end
end
