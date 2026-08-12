# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_audit_logs_examples'

RSpec.describe Channel, type: :model do
  it_behaves_like 'HasAuditLogs', update_attribute: 'active', update_value: false, name_attribute: 'area'

  describe 'sensitive values masking' do
    subject(:channel) do
      create(:channel, area: 'Facebook::Account', options: {
               adapter: 'facebook',
               auth:    { access_token: 'user-token' },
               pages:   [
                 { id: '1', name: 'Page 1', access_token: 'page-1-token' },
                 { id: '2', name: 'Page 2', access_token: 'page-2-token' },
               ],
             })
    end

    let(:masked_pages) do
      [
        { 'id' => '1', 'name' => 'Page 1', 'access_token' => SensitiveParamsHelper::SENSITIVE_MASK },
        { 'id' => '2', 'name' => 'Page 2', 'access_token' => SensitiveParamsHelper::SENSITIVE_MASK },
      ]
    end

    before do
      Setting.set('system_init_done', true)
    end

    it 'masks the Facebook page access tokens in audit log snapshots' do
      expect(AuditLog.find_by(auditable: channel, action_type: 'create').value_to.dig('options', 'pages'))
        .to eq(masked_pages)
    end

    it 'masks the Facebook page access tokens in both snapshots of an update' do
      channel.update!(options: channel.options.merge('sync' => { 'pages' => {} }))

      expect(AuditLog.find_by(auditable: channel, action_type: 'update')).to have_attributes(
        value_from: include('options' => include('pages' => masked_pages)),
        value_to:   include('options' => include('pages' => masked_pages)),
      )
    end

    it 'masks the Facebook page access tokens in assets' do
      expect(channel.assets({}).dig(:Channel, channel.id, 'options', 'pages')).to eq(masked_pages)
    end

    it 'does not modify the channel options' do
      expect { channel.assets({}) }.not_to change { channel.options.to_json }
    end
  end

  describe '.fetch' do

    describe '#refresh_xoauth2! fails' do

      let(:channel) { create(:channel, area: 'SomeXOAUTH2::Account', options: { adapter: 'DummyXOAUTH2', auth: { type: 'XOAUTH2' } }) }

      before do
        allow(ExternalCredential).to receive(:refresh_token).and_raise(RuntimeError)
      end

      it 'changes Channel status to error' do
        expect { described_class.fetch }.to change { channel.reload.status_in }.to('error')
      end
    end

    context 'when one adapter fetch fails' do

      let(:failing_adapter_class) do
        Class.new(Channel::Driver::Null) do
          def fetchable?(...)
            true
          end

          def fetch(...)
            raise 'some error'
          end
        end
      end

      let(:dummy_adapter_class) do
        Class.new(Channel::Driver::Null) do
          def fetchable?(...)
            true
          end
        end
      end

      let(:failing_channel) do
        create(:email_channel, inbound: {
                 adapter: 'failing',
                 options: {}
               })
      end

      let(:other_channel) do
        create(:email_channel, inbound: {
                 adapter: 'dummy',
                 options: {}
               })
      end

      before do
        allow(described_class).to receive(:driver_class).with('dummy').and_return(dummy_adapter_class)
        allow(described_class).to receive(:driver_class).with('failing').and_return(failing_adapter_class)

        failing_channel
        other_channel
      end

      it 'adds error flag to the failing Channel' do
        expect { described_class.fetch }.to change { failing_channel.reload.preferences[:last_fetch] }.and change { failing_channel.reload.status_in }.to('error')
      end

      it 'fetches others anyway' do
        expect { described_class.fetch }.to change { other_channel.reload.preferences[:last_fetch] }.and change { other_channel.reload.status_in }.to('ok')
      end
    end
  end

  describe '.fetch_async', performs_jobs: true do
    let(:channel)              { create(:email_channel) }
    let(:channel_inactive)     { create(:email_channel, active: false) }
    let(:channel_notification) { create(:email_notification_channel) }

    before do
      channel
      channel_inactive
      channel_notification
    end

    it 'enqueues fetch jobs for active email channels only' do
      expect { described_class.fetch_async }
        .to have_enqueued_job(ChannelFetchJob).once
    end

    it 'enqueues fetch jobs for channels not fetched recently' do
      channel.preferences[:last_fetch] = 1.hour.ago
      channel.save!

      expect { described_class.fetch_async }
        .to have_enqueued_job(ChannelFetchJob).once
    end

    it 'makes sure same channel is not enqueued twice' do
      described_class.fetch_async

      travel 1.hour

      described_class.fetch_async

      expect(ChannelFetchJob).to have_been_enqueued.exactly(:once)
    end
  end

  context 'when authentication type is XOAUTH2' do

    shared_examples 'common XOAUTH2' do

      context 'when token refresh fails' do

        let(:exception) { DummyExternalCredentialsBackendError.new('something unexpected happened here') }

        before do
          stub_const('DummyExternalCredentialsBackendError', Class.new(StandardError))

          allow(ExternalCredential).to receive(:refresh_token).and_raise(exception)
        end

        it 'raises RuntimeError' do
          expect { channel.refresh_xoauth2! }.to raise_exception(RuntimeError, %r{#{exception.message}})
        end
      end

      context 'when non-XOAUTH2 channels are present' do

        let!(:email_address) { create(:email_address, channel: create(:channel, area: 'Some::Other')) }

        before do
          # XOAUTH2 channels refresh their tokens on initialization
          allow(ExternalCredential).to receive(:refresh_token).and_return({
                                                                            access_token: 'S3CR3T'
                                                                          })

          channel
        end

        it "doesn't remove email address assignments" do
          expect { described_class.where(area: channel.area).find_each { nil } }.not_to change { email_address.reload.channel_id }
        end
      end
    end

    context 'when provider is Google' do
      it_behaves_like 'common XOAUTH2' do
        let(:channel) { create(:google_channel) }
      end
    end

    context 'when provider is Microsoft365' do
      it_behaves_like 'common XOAUTH2' do
        let(:channel) { create(:microsoft365_channel) }
      end
    end
  end

  describe 'validations' do
    it 'validates email account uniqueness' do
      expect_any_instance_of(Validations::ChannelEmailAccountUniquenessValidator)
        .to receive(:validate).once

      create(:email_channel)
    end
  end
end
