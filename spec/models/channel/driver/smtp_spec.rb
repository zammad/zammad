# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::Smtp, integration: true, required_envs: %w[MAIL_SERVER MAIL_ADDRESS MAIL_PASS] do
  let(:server_host)     { ENV['MAIL_SERVER'] }
  let(:server_login)    { ENV['MAIL_ADDRESS'] }
  let(:server_password) { ENV['MAIL_PASS'] }
  let(:email_address)   { create(:email_address, name: 'me Helpdesk', email: "some-zammad-#{server_login}") }
  let(:group)           { create(:group, name: 'DeliverTest', email_address: email_address) }
  let(:channel) do
    create(:email_channel,
           group:    group,
           outbound: outbound,
           inbound:  {
             adapter: 'imap',
             options: {
               host:     'mx1.example.com',
               user:     'example',
               password: 'some_pw',
               ssl:      'ssl',
             }
           })
  end
  let(:state_name) { 'new' }
  let(:ticket)     { create(:ticket, title: 'some delivery test', group: group, state_name: state_name) }
  let(:article)    { create(:ticket_article, :outbound_email, ticket: ticket, to: Faker::Internet.unique.email, subject: 'some subject', message_id: 'some@id', body: 'some message delivery test') }

  before do
    freeze_time
    email_address.update!(channel_id: channel.id)
    ticket && article
  end

  context 'when modifying channel options', :aggregate_failures do
    let(:outbound) { { adapter: 'sendmail' } }

    it 'updates article delivery preferences' do
      expect(article.preferences).not_to include(:delivery_retry,
                                                 :delivery_status,
                                                 :delivery_status_date,
                                                 :delivery_status_message)

      TicketArticleCommunicateEmailJob.new.perform(article.id)

      expect(article.reload.preferences).to include(delivery_retry:          1,
                                                    delivery_status:         'success',
                                                    delivery_status_date:    be_present,
                                                    delivery_status_message: be_nil)

      # Send with invalid smtp settings.
      channel.options.tap do |options|
        options['outbound'] = {
          adapter: 'smtp',
          options: {
            host:      'mx1.example.com',
            port:      25,
            start_tls: true,
            user:      'not_existing',
            password:  'not_existing',
          },
        }
      end
      channel.save!

      expect { TicketArticleCommunicateEmailJob.new.perform(article.id) }.to raise_error(RuntimeError)

      expect(article.reload.preferences).to include(delivery_retry:          2,
                                                    delivery_status:         'fail',
                                                    delivery_status_date:    be_present,
                                                    delivery_status_message: be_present)

      # Send with valid smtp settings.
      channel.options.tap do |options|
        options['outbound'] = {
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
      end
      channel.save!

      TicketArticleCommunicateEmailJob.new.perform(article.id)

      expect(article.reload.preferences).to include(delivery_retry:          3,
                                                    delivery_status:         'success',
                                                    delivery_status_date:    be_present,
                                                    delivery_status_message: be_nil)
    end
  end

  context 'when encounters sending errors', :aggregate_failures, performs_jobs: true do
    let(:state_name) { 'closed' }
    let(:outbound) do
      {
        adapter: 'smtp',
        options: {
          host:      'mx1.example.com',
          port:      25,
          start_tls: true,
          user:      'not_existing',
          password:  'not_existing',
        },
      }
    end

    it 'retries delivery in expected intervals' do
      expect do
        perform_enqueued_jobs
      end.to have_performed_job(TicketArticleCommunicateEmailJob)

      expect(ticket.reload.articles.count).to eq(1)
      expect(ticket.state.name).to eq('closed')
      expect(article.reload.preferences).to include(delivery_retry:          1,
                                                    delivery_status:         'fail',
                                                    delivery_status_date:    be_present,
                                                    delivery_status_message: be_present)

      expect do
        perform_enqueued_jobs
      end.to have_performed_job(TicketArticleCommunicateEmailJob).at(25.seconds.from_now)

      expect(article.reload.preferences).to include(delivery_retry:          2,
                                                    delivery_status:         'fail',
                                                    delivery_status_date:    be_present,
                                                    delivery_status_message: be_present)
      expect(ticket.reload.articles.count).to eq(1)
      expect(ticket.state.name).to eq('closed')

      expect do
        perform_enqueued_jobs
      end.to have_performed_job(TicketArticleCommunicateEmailJob).at(50.seconds.from_now)

      expect(article.reload.preferences).to include(delivery_retry:          3,
                                                    delivery_status:         'fail',
                                                    delivery_status_date:    be_present,
                                                    delivery_status_message: be_present)
      expect(ticket.reload.articles.count).to eq(1)
      expect(ticket.state.name).to eq('closed')

      expect do
        perform_enqueued_jobs
      end.to raise_error(RuntimeError).and have_performed_job(TicketArticleCommunicateEmailJob).at(75.seconds.from_now)

      expect(article.reload.preferences).to include(delivery_retry:          4,
                                                    delivery_status:         'fail',
                                                    delivery_status_date:    be_present,
                                                    delivery_status_message: be_present)
      expect(ticket.reload.articles.count).to eq(2)
      expect(ticket.state).to eq(Ticket::State.find_by(default_follow_up: true))
      expect(ticket.articles.last).to have_attributes(sender:      Ticket::Article::Sender.lookup(name: 'System'),
                                                      preferences: include(delivery_message:            true,
                                                                           delivery_article_id_related: article.id,
                                                                           notification:                true))
    end
  end

  describe '#prepare_options' do
    let(:instance) { described_class.new }
    let(:outbound) do
      {
        adapter: 'smtp',
        options: {
          host:      'mx1.example.com',
          port:      25,
          start_tls: true,
          user:      'not_existing',
          password:  'not_existing',
        },
      }
    end

    describe 'domain' do
      context 'when domain is given' do
        it 'uses the given one' do
          expect(instance.prepare_options({ domain: 'outgoing.com' }, {}))
            .to include(domain: 'outgoing.com')
        end
      end

      context 'when domain is not given' do
        it 'uses FQDN' do
          expect(instance.prepare_options({}, {}))
            .to include(domain: 'zammad.example.com')
        end

        it 'uses FQDN without port number if it was included' do
          Setting.set('fqdn', 'with.port.com:3000')

          expect(instance.prepare_options({}, {}))
            .to include(domain: 'with.port.com')
        end

        it 'uses FROM address domain if FQDN is a local address' do
          Setting.set('fqdn', 'localhost.local')

          expect(instance.prepare_options({}, { from: 'test@example.com' }))
            .to include(domain: 'example.com')
        end

        it 'uses local FQDN if FROM is not set' do
          Setting.set('fqdn', 'localhost.local')

          expect(instance.prepare_options({}, {}))
            .to include(domain: 'localhost.local')
        end
      end
    end
  end

  describe '#deliver' do
    let(:channel) { create(:email_channel, :smtp) }

    context 'when an error is raised', aggregate_failures: true do
      before do
        allow_any_instance_of(Mail::Message).to receive(:deliver).and_raise(error)
      end

      context 'when the error is one of the predefined errors' do
        let(:error) { Net::OpenTimeout.new('Could not reach server') }

        it 'raises an error with a humanized message' do
          expect { channel.deliver({}) }
            .to raise_error(Channel::DeliveryError) { |error|
              expect(error.original_error.message)
                .to eq("Network connection to 'smtp.example.com' (port 465) timed out: Could not reach server")
            }
        end
      end

      context 'when the error is unknown' do
        let(:error) { StandardError.new('custom error message') }

        it 'forwards the error' do
          expect { channel.deliver({}) }
            .to raise_error(Channel::DeliveryError) { |error|
              expect(error.original_error.message).to eq("'smtp.example.com' (port 465): custom error message")
            }
        end
      end

      context 'when it was sending a notification' do
        let(:error) { Net::SMTPUnknownError.new(error_response, message: 'smtp error') }
        let(:error_response) { Net::SMTP::Response.parse("#{error_code} dummy error") }

        context 'when the error is silenceable' do
          let(:error_code) { 400 }

          it 'raises no error' do
            expect { channel.deliver({}, true) }
              .not_to raise_error
          end
        end

        context 'when the error is not silenceable' do
          let(:error_code) { 123 }

          it 'raises an error' do
            expect { channel.deliver({}, true) }
              .to raise_error(Channel::DeliveryError) { |error|
                expect(error.original_error.message).to eq("'smtp.example.com' (port 465): smtp error")
              }
          end
        end
      end
    end
  end
end
