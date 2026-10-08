# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketArticleCommunicateEmailJob, type: :job do
  describe '#perform' do
    context 'for an email article' do
      let(:article)        { create(:ticket_article, type_name: 'email') }
      let(:recipient_list) { [article.to, article.cc].compact_blank.join(',') }

      before { allow(Rails.logger).to receive(:info) }

      # What we _really_ want is to expect an email to be sent.
      # So why are we testing log messages instead?
      #
      # Because so far, our attempts to test email dispatch have either
      # a) been closely tied to implementation, with lots of ugly mock objects; or
      # b) had to test faraway classes like Channel::Driver::Imap.
      #
      # In other words, this test is NOT set in stone, and very open to improvement.
      it 'records outgoing email dispatch to Rails log' do
        described_class.perform_now(article.id)

        expect(Rails.logger)
          .to have_received(:info)
          .with("Send email to: '#{recipient_list}' (from #{article.from})")
      end
    end

    # https://github.com/zammad/zammad/issues/5523
    context 'when channel is deactivated' do
      let(:email_address) { create(:email_address, channel:) }
      let(:group)   { create(:group, email_address:) }
      let(:channel) { create(:channel, active: false) }
      let(:ticket)  { create(:ticket, group:) }
      let(:article) { create(:ticket_article, :outbound_email, ticket:) }

      before do
        allow(Rails.logger).to receive(:error)

        email_address && ticket
        channel.update!(group:)
      end

      it 'does not send email' do
        expect_any_instance_of(Channel).not_to receive(:deliver)

        described_class.perform_now(article.id)
      end

      it 'logs an error' do
        described_class.perform_now(article.id)

        expect(Rails.logger)
          .to have_received(:error)
          .with("Channel defined for email address id '#{email_address.id}' is not active!")
      end
    end
  end

  describe 'delivery status', :aggregate_failures, performs_jobs: true do
    let(:ticket)  { create(:ticket, state_name: 'closed') }
    let(:article) { create(:ticket_article, :outbound_email, ticket: ticket) }

    before do
      freeze_time
      allow_any_instance_of(Channel).to receive(:deliver).and_raise(StandardError, 'delivery failed')
      article
      clear_jobs
      described_class.perform_later(article.id)
    end

    it 'retries a failing delivery in expected intervals' do
      expect { perform_enqueued_jobs }.to have_performed_job(described_class)

      expect(article.reload.preferences).to include(delivery_retry:          1,
                                                    delivery_status:         'fail',
                                                    delivery_status_date:    be_present,
                                                    delivery_status_message: 'delivery failed')
      expect(ticket.reload.articles.count).to eq(1)
      expect(ticket.state.name).to eq('closed')

      expect { perform_enqueued_jobs }.to have_performed_job(described_class).at(25.seconds.from_now)

      expect(article.reload.preferences).to include(delivery_retry: 2, delivery_status: 'fail')
      expect(ticket.reload.articles.count).to eq(1)
      expect(ticket.state.name).to eq('closed')

      expect { perform_enqueued_jobs }.to have_performed_job(described_class).at(50.seconds.from_now)

      expect(article.reload.preferences).to include(delivery_retry: 3, delivery_status: 'fail')
      expect(ticket.reload.articles.count).to eq(1)
      expect(ticket.state.name).to eq('closed')

      expect { perform_enqueued_jobs }
        .to raise_error(RuntimeError, 'delivery failed')
        .and have_performed_job(described_class).at(75.seconds.from_now)

      expect(article.reload.preferences).to include(delivery_retry: 4, delivery_status: 'fail')
      expect(ticket.reload.articles.count).to eq(2)
      expect(ticket.state).to eq(Ticket::State.find_by(default_follow_up: true))
      expect(ticket.articles.last).to have_attributes(sender:      Ticket::Article::Sender.lookup(name: 'System'),
                                                      preferences: include(delivery_message:            true,
                                                                           delivery_article_id_related: article.id,
                                                                           notification:                true))
    end
  end

  describe 'delivery status with changing channel options', :aggregate_failures, integration: true, required_envs: %w[MAIL_SERVER MAIL_ADDRESS MAIL_PASS] do
    let(:server_host)     { ENV['MAIL_SERVER'] }
    let(:server_login)    { ENV['MAIL_ADDRESS'] }
    let(:server_password) { ENV['MAIL_PASS'] }
    let(:email_address)   { create(:email_address, name: 'me Helpdesk', email: "some-zammad-#{server_login}") }
    let(:group)           { create(:group, name: 'DeliverTest', email_address: email_address) }
    let(:channel)         { create(:email_channel, group: group, outbound: { adapter: 'sendmail' }) }
    let(:ticket)          { create(:ticket, title: 'some delivery test', group: group) }
    let(:article)         { create(:ticket_article, :outbound_email, ticket: ticket, to: Faker::Internet.unique.email, subject: 'some subject', message_id: 'some@id', body: 'some message delivery test') }

    before do
      email_address.update!(channel_id: channel.id)
      article
    end

    it 'updates article delivery preferences' do
      expect(article.preferences).not_to include(:delivery_retry,
                                                 :delivery_status,
                                                 :delivery_status_date,
                                                 :delivery_status_message)

      described_class.new.perform(article.id)

      expect(article.reload.preferences).to include(delivery_retry:          1,
                                                    delivery_status:         'success',
                                                    delivery_status_date:    be_present,
                                                    delivery_status_message: be_nil)

      channel.options['outbound'] = {
        adapter: 'smtp',
        options: {
          host:      'mx1.example.com',
          port:      25,
          start_tls: true,
          user:      'not_existing',
          password:  'not_existing',
        },
      }
      channel.save!

      expect { described_class.new.perform(article.id) }.to raise_error(RuntimeError)

      expect(article.reload.preferences).to include(delivery_retry:          2,
                                                    delivery_status:         'fail',
                                                    delivery_status_date:    be_present,
                                                    delivery_status_message: be_present)

      channel.options['outbound'] = {
        adapter: 'smtp',
        options: {
          host:       server_host,
          port:       25,
          start_tls:  true,
          user:       server_login,
          password:   server_password,
          ssl_verify: false,
        },
      }
      channel.save!

      described_class.new.perform(article.id)

      expect(article.reload.preferences).to include(delivery_retry:          3,
                                                    delivery_status:         'success',
                                                    delivery_status_date:    be_present,
                                                    delivery_status_message: be_nil)
    end
  end

  describe 'MicrosoftGraph::ApiError handling' do
    let(:job) { described_class.perform_later(article.id) }
    let(:article) { create(:ticket_article, :outbound_email) }
    let(:error_hash) do
      {
        'error' => {
          'code'       => 'TooManyRequests',
          'message'    => 'Too many requests. Please try again later.',
          'innerError' => {
            'date'              => '2025-07-31T10:00:00',
            'request-id'        => 'MS_GRAPH_TOKEN',
            'client-request-id' => 'MS_GRAPH_TOKEN'
          }
        }
      }
    end

    before do
      allow_any_instance_of(Channel).to receive(:deliver).and_raise(error)
    end

    context 'when error has Retry-After time' do
      let(:time)  { 1.hour.from_now }
      let(:error) { MicrosoftGraph::ApiError.new(error_hash['error'], retry_after: time) }

      it 'uses Retry-After time' do
        ActiveJob::Base.execute job.serialize

        new_job = enqueued_jobs.last

        expect(new_job[:at]).to be_within(1.second).of(time.to_i)
      end

      it 'stops after 4 attempts' do
        ActiveJob::Base.execute job.serialize

        4.times do
          new_job = enqueued_jobs.last
          enqueued_jobs.clear
          ActiveJob::Base.execute new_job
        end

        expect(enqueued_jobs).to be_empty
      end

      it 'creates error article after 4 attempts' do
        ActiveJob::Base.execute job.serialize

        4.times do
          new_job = enqueued_jobs.last
          enqueued_jobs.clear
          ActiveJob::Base.execute new_job
        end

        expect(Ticket::Article.last).to have_attributes(
          body: "Unable to send email to '#{article.to}': Too many requests. Please try again later. (TooManyRequests)\nMicrosoft Graph API Request ID: MS_GRAPH_TOKEN"
        )
      end
    end

    context 'when error has no Retry-After' do
      let(:error) { MicrosoftGraph::ApiError.new(error_hash['error']) }

      it 'uses back-off timer' do
        ActiveJob::Base.execute job.serialize

        new_job = enqueued_jobs.last

        expect(new_job[:at]).to be_within(1.second).of(25.seconds.from_now.to_i)
      end

      it 'stops after 4 attempts' do
        ActiveJob::Base.execute job.serialize

        4.times do
          new_job = enqueued_jobs.last
          enqueued_jobs.clear
          ActiveJob::Base.execute new_job
        end

        expect(enqueued_jobs).to be_empty
      end

      it 'creates error article after 4 attempts' do
        ActiveJob::Base.execute job.serialize

        4.times do
          new_job = enqueued_jobs.last
          enqueued_jobs.clear
          ActiveJob::Base.execute new_job
        end

        expect(Ticket::Article.last).to have_attributes(
          body: "Unable to send email to '#{article.to}': Too many requests. Please try again later. (TooManyRequests)\nMicrosoft Graph API Request ID: MS_GRAPH_TOKEN"
        )
      end
    end
  end
end
