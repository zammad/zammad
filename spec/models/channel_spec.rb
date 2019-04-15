require 'rails_helper'

RSpec.describe Channel do
  describe '#fetch' do
    around do |example|
      VCR.use_cassette(cassette, match_requests_on: %i[method uri oauth_headers]) { example.run }
    end

    context 'for Twitter driver' do
      subject(:twitter_channel) { create(:twitter_channel) }

      context 'with invalid token' do
        let(:cassette) { 'models/channel/driver/twitter/fetch_channel_invalid' }

        it 'returns false' do
          expect(twitter_channel.fetch(true)).to be(false)
        end

        it 'sets error/nil status attributes' do
          expect { twitter_channel.fetch(true) }
            .to change { twitter_channel.reload.attributes }
            .to hash_including(
              'status_in'    => 'error',
              'last_log_in'  => "Can't use Channel::Driver::Twitter: " \
                                '#<Twitter::Error::Unauthorized: Invalid or expired token.>',
              'status_out'   => nil,
              'last_log_out' => nil
            )
        end
      end

      context 'with valid token' do
        let(:cassette) { 'models/channel/driver/twitter/fetch_channel_valid' }

        it 'returns true' do
          expect(twitter_channel.fetch(true)).to be(true)
        end

        it 'sets successful status attributes' do
          expect { twitter_channel.fetch(true) }
            .to change { twitter_channel.reload.attributes }
            .to hash_including(
              'status_in'    => 'ok',
              'last_log_in'  => '',
              'status_out'   => nil,
              'last_log_out' => nil
            )
        end

        it 'adds tickets as appropriate' do
          expect { twitter_channel.fetch(true) }
            .to change(Ticket, :count).by(26)

          expect(Ticket.last.attributes).to include(
            'title'       => 'Wir haben unsere DMs deaktiviert. ' \
                             'Leider können wir dank der neuen Twitter API k...',
            'preferences' => { 'channel_id'          => twitter_channel.id,
                               'channel_screen_name' => twitter_channel.options[:user][:screen_name] },
            'customer_id' => User.find_by(firstname: 'Ccc', lastname: 'Event Logistics').id
          )
        end
      end
    end
  end
end
