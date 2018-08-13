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
