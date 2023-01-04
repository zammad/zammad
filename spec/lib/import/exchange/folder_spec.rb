# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'viewpoint' # Only load this gem when it is really used.

#
# DEPRECATION WARNING
#
# Microsoft announced in July 2018 that Exchange Web Services (EWS) API will not receive any feature updates. This
# effectively freezes the structure of expected responses that are mocked in this test via VCR cassettes.
#
# https://techcommunity.microsoft.com/t5/exchange-team-blog/upcoming-changes-to-exchange-web-services-ews-api-for-office-365/ba-p/608055
#
# Furthermore, in September 2022, Microsoft also announced that they will start to turn off basic auth for EWS
# protocol in Exchange Online. As of this writing, it's not possible to recreate the test responses to EWS API used
# below without an on-premise system to serve them.
#
# https://techcommunity.microsoft.com/t5/exchange-team-blog/basic-authentication-deprecation-in-exchange-online-september/ba-p/3609437

RSpec.describe Import::Exchange::Folder, :integration do

  # see https://github.com/zammad/zammad/issues/2152
  describe '#display_path (#2152)', :use_vcr do
    subject(:folder)         { described_class.new(ews_connection) }

    let(:ews_connection)     { Viewpoint::EWSClient.new(endpoint, user, pass) }
    let(:endpoint)           { 'https://exchange.example.com/EWS/Exchange.asmx' }
    let(:user)               { 'user@example.com' }
    let(:pass)               { 'password' }
    let(:grandchild_of_root) { ews_connection.get_folder_by_name('Inbox') }
    let(:child_of_root)      { ews_connection.get_folder(grandchild_of_root.parent_folder_id) }

    before do
      if VCR.configuration.allow_http_connections_when_no_cassette?
        skip 'This test example requires a VCR cassette to work, and they are disabled in the current environment.'
      end
    end

    context 'when server returns valid UTF-8' do
      context 'and target folder is in root directory' do
        it 'returns the display name of the folder' do
          expect(folder.display_path(child_of_root))
            .to eq('Top of Information Store')
        end
      end

      context 'and target folder is in subfolder of root' do
        it 'returns the full path from root to target' do
          expect(folder.display_path(grandchild_of_root))
            .to eq('Top of Information Store -> Inbox')
        end
      end

      context 'and walking up directory tree raises EwsError' do
        it 'returns the partial path from error to target folder' do
          allow(folder)
            .to receive(:id_folder_map).with(any_args).and_raise(Viewpoint::EWS::EwsError)

          expect(folder.display_path(grandchild_of_root))
            .to eq('Inbox')
        end
      end
    end

    context 'when server returns invalid UTF-8' do
      context 'and target folder is in root directory' do
        it 'returns the display name of the folder in valid UTF-8' do
          allow(child_of_root)
            .to receive(:display_name).and_return('你好'.b)

          expect { folder.display_path(child_of_root).to_json }.not_to raise_error
        end
      end

      context 'and target folder is in subfolder of root' do
        it 'returns the full path from root to target in valid UTF-8' do
          allow(grandchild_of_root)
            .to receive(:display_name).and_return('你好'.b)

          expect { folder.display_path(grandchild_of_root).to_json }.not_to raise_error
        end
      end

      context 'and walking up directory tree raises EwsError' do
        it 'returns the partial path from error to target folder in valid UTF-8' do
          allow(grandchild_of_root)
            .to receive(:display_name).and_return('你好'.b)
          allow(folder)
            .to receive(:id_folder_map).with(any_args).and_raise(Viewpoint::EWS::EwsError)

          expect { folder.display_path(grandchild_of_root).to_json }.not_to raise_error
        end
      end
    end
  end
end
