# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Article::EnqueueCommunicateEmailJob, performs_jobs: true do
  before { allow(Delayed::Job).to receive(:enqueue).and_call_original }

  let(:article) { create(:ticket_article, **(try(:factory_options) || {})) }

  let(:channel) do
    create(:email_channel, outbound: {
             'adapter' => 'smtp',
             'options' => {
               'host'           => '10.1.1.1',
               'port'           => 25,
               'ssl'            => true,
               'ssl_verify'     => true,
               'user'           => 'other@example.com',
               'password'       => 'somepass',
               'authentication' => nil
             }
           })
  end

  shared_examples 'for no-op' do
    it 'is a no-op' do
      expect { article }.not_to have_enqueued_job(TicketArticleCommunicateEmailJob)
    end
  end

  shared_examples 'for success' do
    it 'enqueues the Email background job' do
      expect { article }.to have_enqueued_job(TicketArticleCommunicateEmailJob)
    end
  end

  shared_examples 'for failure' do
    it 'executes the enqueued Email background job that will time out', :aggregate_failures do
      stub_const('Channel::Driver::Smtp::DEFAULT_OPEN_TIMEOUT', 0.01)
      stub_const('Channel::Driver::Smtp::DEFAULT_READ_TIMEOUT', 0.01)

      expect { article.ticket.group.email_address.update(channel:) }.to have_enqueued_job(TicketArticleCommunicateEmailJob)
      expect(TicketArticleCommunicateEmailJob).to have_been_enqueued

      expect { perform_enqueued_jobs commit_transaction: true }.not_to raise_error

      expect(article.reload.preferences).to include(
        delivery_status:         'fail',
        delivery_status_message: "Smtp: Network connection to '10.1.1.1' (port 25) timed out: execution expired (Net::OpenTimeout)",
      )

      expect(channel.reload).to have_attributes(
        status_out:   'error',
        last_log_out: "Smtp: Network connection to '10.1.1.1' (port 25) timed out: execution expired (Net::OpenTimeout)",
      )
    end
  end

  context 'when in Import Mode' do
    before { Setting.set('import_mode', true) }

    include_examples 'for no-op'
  end

  context 'when article is created during Channel::EmailParser#process', application_handle: 'scheduler.postmaster' do
    include_examples 'for no-op'
  end

  context 'when article is from a customer' do
    let(:factory_options) { { sender_name: 'Customer' } }

    include_examples 'for no-op'
  end

  context 'when article is an email' do
    let(:factory_options) { { sender_name: 'Agent', type_name: 'email' } }

    include_examples 'for success'
  end

  context 'when article is an email but cannot be sent' do
    let(:factory_options) { { sender_name: 'Agent', type_name: 'email' } }

    include_examples 'for failure'
  end
end
