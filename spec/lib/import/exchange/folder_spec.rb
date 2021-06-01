# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::Exchange::Folder do
  # see https://github.com/zammad/zammad/issues/2152

  describe '#display_path (#2152)', :use_vcr do
    let(:subject)            { described_class.new(ews_connection) }
    let(:ews_connection)     { Viewpoint::EWSClient.new(endpoint, user, pass) }
    let(:endpoint)           { 'https://exchange.example.com/EWS/Exchange.asmx' }
    let(:user)               { 'user@example.com' }
    let(:pass)               { 'password' }
    let(:grandchild_of_root) { ews_connection.get_folder_by_name('Inbox') }
    let(:child_of_root)      { ews_connection.get_folder(grandchild_of_root.parent_folder_id) }

    context 'when server returns valid UTF-8' do
      context 'and target folder is in root directory' do
        it 'returns the display name of the folder' do
          expect(subject.display_path(child_of_root))
            .to eq('Top of Information Store')
        end
      end

      context 'and target folder is in subfolder of root' do
        it 'returns the full path from root to target' do
          expect(subject.display_path(grandchild_of_root))
            .to eq('Top of Information Store -> Inbox')
        end
      end

      context 'and walking up directory tree raises EwsError' do
        it 'returns the partial path from error to target folder' do
          allow(subject)
            .to receive(:id_folder_map).with(any_args).and_raise(Viewpoint::EWS::EwsError)

          expect(subject.display_path(grandchild_of_root))
            .to eq('Inbox')
        end
      end
    end

    context 'when server returns invalid UTF-8' do
      context 'and target folder is in root directory' do
        it 'returns the display name of the folder in valid UTF-8' do
          allow(child_of_root)
            .to receive(:display_name).and_return('你好'.b)

          expect { subject.display_path(child_of_root).to_json }.not_to raise_error
        end
      end

      context 'and target folder is in subfolder of root' do
        it 'returns the full path from root to target in valid UTF-8' do
          allow(grandchild_of_root)
            .to receive(:display_name).and_return('你好'.b)

          expect { subject.display_path(grandchild_of_root).to_json }.not_to raise_error
        end
      end

      context 'and walking up directory tree raises EwsError' do
        it 'returns the partial path from error to target folder in valid UTF-8' do
          allow(grandchild_of_root)
            .to receive(:display_name).and_return('你好'.b)
          allow(subject)
            .to receive(:id_folder_map).with(any_args).and_raise(Viewpoint::EWS::EwsError)

          expect { subject.display_path(grandchild_of_root).to_json }.not_to raise_error
        end
      end
    end
  end
end
