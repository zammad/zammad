# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe Webhook, type: :model do

  it_behaves_like 'HasXssSanitizedNote', model_factory: :webhook

  describe 'check endpoint' do
    subject(:webhook) { build(:webhook, endpoint: endpoint) }

    before { webhook.valid? }

    let(:endpoint_errors) { webhook.errors.messages[:endpoint] }

    context 'with missing http type' do
      let(:endpoint) { 'example.com' }

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(endpoint_errors).to include 'Invalid endpoint (no http/https)!'
      end
    end

    context 'with spaces in invalid hostname' do
      let(:endpoint) { 'http://   example.com' }

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(endpoint_errors).to include 'Invalid endpoint!'
      end
    end

    context 'with ? in hostname' do
      let(:endpoint) { 'http://?example.com' }

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(endpoint_errors).to include 'Invalid endpoint (no hostname)!'
      end
    end

    context 'with nil in endpoint' do
      let(:endpoint) { nil }

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(endpoint_errors).to include 'Invalid endpoint!'
      end
    end

    context 'with a valid endpoint' do
      let(:endpoint) { 'https://example.com/endpoint' }

      it { is_expected.to be_valid }

      it 'has no errors' do
        expect(endpoint_errors).to be_empty
      end
    end
  end

  describe '#destroy' do
    subject(:webhook) { create(:webhook) }

    context 'when no dependencies' do
      it 'removes the object' do
        expect { webhook.destroy }.to change(webhook, :destroyed?).to true
      end
    end

    context 'when related object exists' do
      let!(:trigger) { create(:trigger, perform: { 'notification.webhook' => { 'webhook_id' => webhook.id.to_s } }) }

      it 'raises error with details' do
        expect { webhook.destroy }.to raise_error(Exceptions::UnprocessableEntity, %r{#{Regexp.escape("Trigger: #{trigger.name} (##{trigger.id})")}})
      end
    end
  end
end
