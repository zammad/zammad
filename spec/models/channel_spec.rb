require 'rails_helper'

RSpec.describe Channel, type: :model do

  context 'when authentication type is XOAUTH2' do

    shared_examples 'common XOAUTH2' do

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
