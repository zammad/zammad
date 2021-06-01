# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel, type: :model do

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
          def fetchable?(*)
            true
          end

          def fetch(*)
            raise 'some error'
          end
        end
      end

      let(:dummy_adapter_class) do
        Class.new(Channel::Driver::Null) do
          def fetchable?(*)
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
end
