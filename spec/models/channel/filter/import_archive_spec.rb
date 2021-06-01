# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::ImportArchive do

  let!(:agent1) { create(:agent, groups: Group.all) }

  let(:channel_as_model) do
    Channel.new(options: { inbound: { options: { archive: true } } })
  end

  let(:channel_as_hash) do
    { options: { inbound: { options: { archive: true } } } }
  end

  let(:mail001) do
    email_file_path = Rails.root.join('test/data/mail/mail001.box')
    File.read(email_file_path)
  end

  let(:email_parse_mail001) do
    email_raw_string = mail001
    Channel::EmailParser.new.process(channel_as_model, email_raw_string)
  end

  let(:email_parse_mail001_hash) do
    email_raw_string = mail001
    Channel::EmailParser.new.process(channel_as_hash, email_raw_string)
  end

  let(:email_parse_mail001_answer) do
    email_raw_string = mail001
    email_raw_string.gsub!('Date: Thu, 3 May 2012 11:36:43 +0200', 'Date: Thu, 3 May 2014 11:36:43 +0200')
    email_raw_string.gsub!('Message-Id: <053EA3703574649ABDAF24D43A05604F327A130@MEMASFRK004.example.com>', "In-Reply-To: <053EA3703574649ABDAF24D43A05604F327A130@MEMASFRK004.example.com>\nMessage-Id: <053EA3703574649ABDAF24D43A05604F327A130-1@MEMASFRK004.example.com>")

    Channel::EmailParser.new.process(channel_as_model, email_raw_string)
  end

  shared_examples 'import archive base checks' do |ticket_create_date, article_create_date, article_count|
    it 'checks if the state is closed' do
      ticket1_p, _article1_p, _user1_p = email_parse_mail001
      expect(ticket1_p.state.name).to eq('closed')
    end

    it 'checks if the article got created' do
      ticket1_p, _article1_p, _user1_p = email_parse_mail001
      expect(ticket1_p.articles.count).to eq(article_count)
    end

    it 'checks if the ticket create date is correct' do
      ticket1_p, _article1_p, _user1_p = email_parse_mail001
      expect(ticket1_p.created_at).to eq(Time.zone.parse(ticket_create_date))
    end

    it 'checks if the article create date is correct' do
      _ticket1_p, article1_p, _user1_p = email_parse_mail001
      expect(article1_p.created_at).to eq(Time.zone.parse(article_create_date))
    end
  end

  shared_examples 'import archive answer checks' do |ticket_create_date, article_create_date, article_count|
    it 'checks if the state is closed' do
      ticket1_p, _article1_p, _user1_p = email_parse_mail001_answer
      expect(ticket1_p.state.name).to eq('closed')
    end

    it 'checks if the article got created' do
      ticket1_p, _article1_p, _user1_p = email_parse_mail001_answer
      expect(ticket1_p.articles.count).to eq(article_count)
    end

    it 'checks if the ticket create date is correct' do
      ticket1_p, _article1_p, _user1_p = email_parse_mail001_answer
      expect(ticket1_p.created_at).to eq(Time.zone.parse(ticket_create_date))
    end

    it 'checks if the article create date is correct' do
      _ticket1_p, article1_p, _user1_p = email_parse_mail001_answer
      expect(article1_p.created_at).to eq(Time.zone.parse(article_create_date))
    end
  end

  shared_examples 'notification sent checks' do |notification_count, parse_hash = false|
    def email_hash(parse_hash)
      if parse_hash
        email_parse_mail001_hash
      else
        email_parse_mail001
      end
    end

    before do
      ticket1_p, article1_p, _user1_p = email_hash(parse_hash)

      Scheduler.worker(true)
      ticket1_p.reload
      article1_p.reload
    end

    it 'verifies if notifications are sent' do
      ticket1_p, _article1_p, _user1_p = email_hash(parse_hash)
      expect(NotificationFactory::Mailer.already_sent?(ticket1_p, agent1, 'email')).to eq(notification_count)
    end
  end

  describe '.run' do

    context 'when initial ticket (import before outdated)' do
      let(:channel_as_model) do
        Channel.new(options: { inbound: { options: { archive: true, archive_before: '2012-03-04 00:00:00' } } })
      end

      include_examples 'notification sent checks', 1
    end

    context 'when initial ticket (import before matched)' do
      let(:channel_as_model) do
        Channel.new(options: { inbound: { options: { archive: true, archive_before: '2012-05-04 00:00:00' } } })
      end

      include_examples 'notification sent checks', 0
    end

    context 'when initial ticket (import till outdated)' do
      let(:channel_as_model) do
        Channel.new(options: { inbound: { options: { archive: true, archive_till: (Time.zone.now - 1.day).to_s } } })
      end

      include_examples 'notification sent checks', 1
    end

    context 'when initial ticket (import till matched)' do
      let(:channel_as_model) do
        Channel.new(options: { inbound: { options: { archive: true, archive_till: (Time.zone.now + 1.day).to_s } } })
      end

      include_examples 'notification sent checks', 0
    end

    context 'when initial ticket (import before outdated) with channel hash' do
      let(:channel_as_hash) do
        { options: { inbound: { options: { archive: true, archive_before: '2012-03-04 00:00:00' } } } }
      end

      include_examples 'notification sent checks', 1, true
    end

    context 'when initial ticket (import before matched) with channel hash' do
      let(:channel_as_hash) do
        { options: { inbound: { options: { archive: true, archive_before: '2012-05-04 00:00:00' } } } }
      end

      include_examples 'notification sent checks', 0, true
    end

    context 'when initial ticket (import till outdated) with channel hash' do
      let(:channel_as_hash) do
        { options: { inbound: { options: { archive: true, archive_till: (Time.zone.now - 1.day).to_s } } } }
      end

      include_examples 'notification sent checks', 1, true
    end

    context 'when initial ticket (import till matched) with channel hash' do
      let(:channel_as_hash) do
        { options: { inbound: { options: { archive: true, archive_till: (Time.zone.now + 1.day).to_s } } } }
      end

      include_examples 'notification sent checks', 0, true
    end

    context 'when initial ticket' do

      include_examples 'import archive base checks', 'Thu, 03 May 2012 09:36:43 UTC +00:00', 'Thu, 03 May 2012 09:36:43 UTC +00:00', 1

      context 'with scheduler run' do
        before do
          ticket1_p, article1_p, _user1_p = email_parse_mail001
          Scheduler.worker(true)
          ticket1_p.reload
          article1_p.reload
        end

        include_examples 'import archive base checks', 'Thu, 03 May 2012 09:36:43 UTC +00:00', 'Thu, 03 May 2012 09:36:43 UTC +00:00', 1

        it 'verifies if notifications are sent' do
          ticket1_p, _article1_p, _user1_p = email_parse_mail001
          expect(NotificationFactory::Mailer.already_sent?(ticket1_p, agent1, 'email')).to eq(0)
        end

        context 'when follow up check (mail answer)' do

          include_examples 'import archive answer checks', 'Thu, 03 May 2012 09:36:43 UTC +00:00', 'Thu, 03 May 2014 09:36:43 UTC +00:00', 2

          it 'checks if the article is different to the first one' do
            _ticket1_p, article1_p, _user1_p = email_parse_mail001
            _ticket2_p, article2_p, _user2_p = email_parse_mail001_answer
            expect(article2_p.id).not_to eq(article1_p.id)
          end

          it 'checks if the article is a followup for the existing ticket' do
            ticket1_p, _article1_p, _user1_p = email_parse_mail001
            ticket2_p, _article2_p, _user2_p = email_parse_mail001_answer
            expect(ticket2_p.id).to eq(ticket1_p.id)
          end

          context 'with scheduler run' do
            before do
              ticket2_p, article2_p, _user2_p = email_parse_mail001_answer
              Scheduler.worker(true)
              ticket2_p.reload
              article2_p.reload
            end

            include_examples 'import archive answer checks', 'Thu, 03 May 2012 09:36:43 UTC +00:00', 'Thu, 03 May 2014 09:36:43 UTC +00:00', 2

            it 'verifies if notifications are sent' do
              ticket2_p, _article2_p, _user2_p = email_parse_mail001_answer
              expect(NotificationFactory::Mailer.already_sent?(ticket2_p, agent1, 'email')).to eq(0)
            end
          end
        end
      end
    end

    context 'when duplicate check with channel as model' do
      before do
        Channel::EmailParser.new.process(channel_as_model, mail001)
      end

      it 'checks that the ticket count does not change on duplicates' do
        expect { Channel::EmailParser.new.process(channel_as_model, mail001) }
          .not_to change(Ticket, :count)
      end
    end

    context 'when duplicate check with channel as hash' do
      before do
        Channel::EmailParser.new.process(channel_as_hash, mail001)
      end

      it 'checks that the ticket count does not change on duplicates' do
        expect { Channel::EmailParser.new.process(channel_as_hash, mail001) }
          .not_to change(Ticket, :count)
      end
    end
  end
end
