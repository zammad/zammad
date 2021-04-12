# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_collection_update_examples'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe EmailAddress, type: :model do
  subject(:email_address) { create(:email_address) }

  it_behaves_like 'HasCollectionUpdate', collection_factory: :email_address
  it_behaves_like 'HasXssSanitizedNote', model_factory: :email_address

  describe 'Attributes:' do
    describe '#active' do
      subject(:email_address) do
        create(:email_address, channel: channel, active: active)
      end

      context 'without a Channel association' do
        let(:channel) { nil }
        let(:active) { true }

        it 'always returns false' do
          expect(email_address.active).not_to eq(active)
        end
      end

      context 'with a Channel association' do
        let(:channel) { create(:email_channel) }
        let(:active) { true }

        it 'returns the value it was set to' do
          expect(email_address.active).to eq(active)
        end
      end
    end
  end

  describe 'Associations:' do
    describe '#groups' do
      let(:group) { create(:group, email_address: email_address) }

      context 'when an EmailAddress is destroyed' do
        it 'removes the #email_address_id from all associated Groups' do
          expect { email_address.destroy }
            .to change { group.reload.email_address_id }.to(nil)
        end
      end
    end

    describe '#channel' do
      subject(:email_addresses) { create_list(:email_address, 2, channel: channel) }

      let(:channel) { create(:channel) }

      context 'when a Channel is destroyed' do
        it 'removes the #channel_id from all its associated EmailAddresses' do
          expect { channel.destroy }
            .to change { email_addresses.map(&:reload).map(&:channel_id) }
            .to([nil, nil])
        end

        context 'and then an identical Channel is created' do
          it 'removes the #channel_id from all its associated EmailAddresses' do
            channel.destroy

            expect { create(:channel) }
              .not_to change { email_addresses.map(&:reload).map(&:channel_id) }
          end
        end
      end
    end
  end
end
