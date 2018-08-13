require 'rails_helper'

RSpec.describe Import::Exchange::Folder do
  # see https://github.com/zammad/zammad/issues/2152
  # WARNING! This test is closely tied to the implementation. :(
  describe '#display_path (#2152)' do
    let(:subject)        { described_class.new(connection) }
    let(:connection)     { instance_double('Viewpoint::EWSClient') }
    let(:root_folder)    { double('EWS Folder') }
    let(:child_folder)   { double('EWS Folder') }
    let(:exception_case) { double('EWS Folder') }

    context 'when server returns valid UTF-8' do
      before do
        allow(root_folder).to receive(:display_name).and_return('Root')
        allow(root_folder).to receive(:parent_folder_id).and_return(nil)

        allow(child_folder).to receive(:display_name).and_return('Leaf')
        allow(child_folder).to receive(:parent_folder_id).and_return(1)

        allow(exception_case).to receive(:display_name).and_return('Error-Raising Leaf')
        allow(exception_case).to receive(:parent_folder_id).and_raise(Viewpoint::EWS::EwsError)

        allow(subject).to receive(:find).with(any_args).and_return(root_folder)
        allow(subject).to receive(:find).with(nil).and_return(nil)
      end

      context 'and target folder is directory root' do
        it 'returns the display name of the folder' do
          expect(subject.display_path(root_folder)).to eq('Root')
        end
      end

      context 'and target folder is NOT directory root' do
        it 'returns the full path from root to target' do
          expect(subject.display_path(child_folder)).to eq('Root -> Leaf')
        end
      end

      context 'and walking up directory tree raises EwsError' do
        it 'returns the partial path from error to target folder' do
          expect(subject.display_path(exception_case)).to eq('Error-Raising Leaf')
        end
      end
    end

    context 'when server returns invalid UTF-8' do
      before do
        allow(root_folder).to receive(:display_name).and_return('你好'.b)
        allow(root_folder).to receive(:parent_folder_id).and_return(nil)

        allow(child_folder).to receive(:display_name).and_return('你好'.b)
        allow(child_folder).to receive(:parent_folder_id).and_return(1)

        allow(exception_case).to receive(:display_name).and_return('你好'.b)
        allow(exception_case).to receive(:parent_folder_id).and_raise(Viewpoint::EWS::EwsError)

        allow(subject).to receive(:find).with(any_args).and_return(root_folder)
        allow(subject).to receive(:find).with(nil).and_return(nil)
      end

      it 'returns a valid UTF-8 string' do
        expect { subject.display_path(root_folder).to_json }.not_to raise_error
        expect { subject.display_path(child_folder).to_json }.not_to raise_error
        expect { subject.display_path(exception_case).to_json }.not_to raise_error
      end
    end
  end
end
