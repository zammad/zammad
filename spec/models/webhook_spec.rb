require 'rails_helper'

RSpec.describe Webhook, type: :model do

  describe 'check endpoint' do
    subject(:webhook) { create(:webhook, endpoint: endpoint) }

    let(:endpoint) { 'example.com' }

    context 'with missing http type' do
      it 'raise an error' do
        expect { webhook }.to raise_error(Exceptions::UnprocessableEntity, 'Invalid endpoint (no http/https)!')
      end
    end

    context 'with spaces in invalid hostname' do
      let(:endpoint) { 'http://   example.com' }

      it 'raise an error' do
        expect { webhook }.to raise_error(Exceptions::UnprocessableEntity, 'Invalid endpoint!')
      end
    end

    context 'with ? in hostname' do
      let(:endpoint) { 'http://?example.com' }

      it 'raise an error' do
        expect { webhook }.to raise_error(Exceptions::UnprocessableEntity, 'Invalid endpoint (no hostname)!')
      end
    end

    context 'with nil in endpoint' do
      let(:endpoint) { nil }

      it 'raise an error' do
        expect { webhook }.to raise_error(Exceptions::UnprocessableEntity, 'Invalid endpoint!')
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
        expect { webhook.destroy }.to raise_error(Exceptions::UnprocessableEntity, /#{Regexp.escape("Trigger: #{trigger.name} (##{trigger.id})")}/)
      end
    end
  end
end
