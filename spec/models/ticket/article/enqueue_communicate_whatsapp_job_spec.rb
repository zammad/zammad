# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Article::EnqueueCommunicateWhatsappJob, performs_jobs: true do
  before { allow(Delayed::Job).to receive(:enqueue).and_call_original }

  let(:article) { create(:ticket_article, **(try(:factory_options) || {})) }

  shared_examples 'for no-op' do
    it 'is a no-op' do
      expect { article }.not_to have_enqueued_job(CommunicateWhatsappJob)
    end
  end

  shared_examples 'for success' do
    it 'enqueues the WhatsApp background job' do
      expect { article }.to have_enqueued_job(CommunicateWhatsappJob)
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

  context 'when article is a whatsapp message' do
    let(:factory_options) { { sender_name: 'Agent', type_name: 'whatsapp message' } }

    include_examples 'for success'
  end
end
