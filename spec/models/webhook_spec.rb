# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe Webhook, type: :model do

  it_behaves_like 'HasXssSanitizedNote', model_factory: :webhook

  describe 'check endpoint' do
    subject(:webhook) { build(:webhook, endpoint: endpoint) }

    let(:endpoint_errors) { webhook.errors.messages[:endpoint] }
    let(:resolved_ip)     { '8.8.8.8' }

    before do
      allow(IPSocket).to receive(:getaddress).and_call_original
      allow(IPSocket).to receive(:getaddress).with('example.com').and_return(resolved_ip)

      webhook.valid?
    end

    context 'with missing http type' do
      let(:endpoint) { 'example.com' }

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(endpoint_errors).to include 'The provided endpoint is invalid, no http or https protocol was specified.'
      end
    end

    context 'with spaces in invalid hostname' do
      let(:endpoint) { 'http://   example.com' }

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(endpoint_errors).to include 'The provided endpoint is invalid.'
      end
    end

    context 'with ? in hostname' do
      let(:endpoint) { 'http://?example.com' }

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(endpoint_errors).to include 'The provided endpoint is invalid, no hostname was specified.'
      end
    end

    context 'with nil in endpoint' do
      let(:endpoint) { nil }

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(endpoint_errors).to include 'The provided endpoint is invalid.'
      end
    end

    context 'with a valid endpoint' do
      let(:endpoint) { 'https://example.com/endpoint' }

      it { is_expected.to be_valid }

      it 'has no errors' do
        expect(endpoint_errors).to be_empty
      end

      context 'when it points to a loopback IP' do
        let(:resolved_ip) { '127.0.0.1' }

        it 'has no errors' do
          expect(endpoint_errors).to be_empty
        end
      end

      context 'when it points to a link-local IP' do
        let(:resolved_ip) { '169.254.123.45' }

        it 'has an error' do
          expect(endpoint_errors).to include 'The provided endpoint is invalid, it points to a link-local IP address.'
        end
      end
    end

    context 'with endpoint longer than 300 characters (#5573)' do
      let(:endpoint) { "https://example.com/#{'endpoint' * 128}" }

      it { is_expected.to be_valid }

      it 'has no errors' do
        expect(endpoint_errors).to be_empty
      end
    end

    context 'with variable placeholders in endpoint' do
      let(:endpoint) { 'https://example.com/webhook/#{ticket.number}' } # rubocop:disable Lint/InterpolationCheck

      it { is_expected.to be_valid }

      it 'has no errors' do
        expect(endpoint_errors).to be_empty
      end
    end

    context 'with multiple variable placeholders in endpoint' do
      let(:endpoint) { 'https://example.com/webhook?ticket=#{ticket.number}&id=#{ticket.id}' } # rubocop:disable Lint/InterpolationCheck

      it { is_expected.to be_valid }

      it 'has no errors' do
        expect(endpoint_errors).to be_empty
      end
    end

    context 'with invalid endpoint and placeholders' do
      let(:endpoint) { 'invalid://#{ticket.number}' } # rubocop:disable Lint/InterpolationCheck

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(endpoint_errors).to include 'The provided endpoint is invalid, no http or https protocol was specified.'
      end
    end
  end

  describe 'check custom payload' do
    subject(:webhook) { build(:webhook, custom_payload: custom_payload) }

    before { webhook.valid? }

    let(:custom_payload_errors) { webhook.errors.messages[:custom_payload] }

    context 'with valid JSON' do
      let(:custom_payload) { '{"foo": "bar"}' }

      it { is_expected.to be_valid }

      it 'has no errors' do
        expect(custom_payload_errors).to be_empty
      end
    end

    context 'with invalid JSON' do
      let(:custom_payload) { '{"foo": bar}' }

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(custom_payload_errors).to include 'The provided payload is invalid. Please check your syntax.'
      end
    end
  end

  describe 'check http_method' do
    subject(:webhook) { build(:webhook, http_method: http_method) }

    before { webhook.valid? }

    let(:http_method_errors) { webhook.errors.messages[:http_method] }

    context 'with valid http_method' do
      %w[post put patch delete].each do |method|
        context "with #{method}" do
          let(:http_method) { method }

          it { is_expected.to be_valid }

          it 'has no errors' do
            expect(http_method_errors).to be_empty
          end
        end
      end
    end

    context 'with uppercase http_method' do
      let(:http_method) { 'POST' }

      it { is_expected.to be_valid }

      it 'has no errors' do
        expect(http_method_errors).to be_empty
      end
    end

    context 'with invalid http_method' do
      let(:http_method) { 'invalid' }

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(http_method_errors).to include 'The provided HTTP method is invalid.'
      end
    end
  end

  describe 'reset custom payload' do
    subject(:webhook) { create(:webhook, customized_payload: customized_payload, custom_payload: custom_payload) }

    context 'with customized payload' do
      let(:customized_payload) { true }
      let(:custom_payload)     { '{"foo": "bar"}' }

      it 'saves custom payload' do
        expect(webhook).to have_attributes(
          customized_payload: customized_payload,
          custom_payload:     custom_payload,
        )
      end
    end

    context 'without customized payload' do
      let(:customized_payload) { false }
      let(:custom_payload)     { '{"foo": "bar"}' }

      it 'resets custom payload' do
        expect(webhook).to have_attributes(
          customized_payload: customized_payload,
          custom_payload:     nil,
        )
      end
    end
  end

  describe 'check preferences' do
    subject(:webhook) { build(:webhook, preferences: preferences) }

    let(:preferences) { { pre_defined: { class_name: 'Webhook::PreDefined::Example' } } }

    it 'has preferences' do
      expect(webhook.preferences).to include({ 'pre_defined' => { 'class_name' => 'Webhook::PreDefined::Example' } })
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
        expect { webhook.destroy }
          .to raise_exception(
            be_an_instance_of(Exceptions::UnprocessableEntity)
            .and(have_attributes(
                   message: 'This object is referenced by other object(s) and thus cannot be deleted: %s',
                   entity:  eq(["Trigger / #{trigger.name} (##{trigger.id})"])
                 ))
          )
      end
    end
  end
end
