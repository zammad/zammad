# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Store::File, type: :model do
  subject(:file) { described_class.add('foo') }

  describe '.add' do
    context 'with no preconfigured storage provider' do
      before { Setting.set('storage_provider', nil) }

      it 'defaults to the "DB" provider' do
        expect(file.provider).to eq('DB')
      end
    end

    context 'with a preconfigured storage provider' do
      before { Setting.set('storage_provider', 'File') }

      after { Store::Provider::File.delete(described_class.checksum('foo')) }

      it 'defaults to the "DB" provider' do
        expect(file.provider).to eq('File')
      end
    end
  end

  describe 'verify' do
    let(:counter) { Set.new }
    let(:stores) do
      [
        create(:store, :txt),
        create(:store, :txt, data: 'foo'),
        create(:store, :txt, data: 'bar')
      ]
    end

    before do
      stores
      allow_any_instance_of(described_class).to receive(:checksum_valid?) { |elem|
        counter << elem.id
        valid?(elem)
      }
    end

    context 'when all files are valid' do
      it 'returns true' do
        expect(described_class.verify).to be_truthy
      end

      it 'runs check for all files' do
        described_class.verify
        expect(counter.count).to eq(3)
      end

      it 'does not update checksum on any files even with fix_it = true' do
        expect_any_instance_of(described_class).not_to receive(:update_checksum!)
        described_class.verify
      end

      def valid?(_elem)
        true
      end
    end

    context 'when one of the files is not valid' do
      it 'returns false' do
        expect(described_class.verify).to be_falsey
      end

      it 'runs check for all files' do
        described_class.verify
        expect(counter.count).to eq(3)
      end

      it 'does not update checksum on any files with fix_it = false' do
        expect_any_instance_of(described_class).not_to receive(:update_checksum!)
        described_class.verify
      end

      it 'updates checksum on the invalid file with fix_it = true' do
        expect_any_instance_of(described_class).to receive(:update_checksum!).once
        described_class.verify(true)
      end

      def valid?(elem)
        elem.id != stores.first.store_file.id
      end
    end
  end

  describe '.move' do
    before { Setting.set('storage_provider', nil) }

    after { Store::Provider::File.delete(described_class.checksum('foo')) }

    let(:storage_path) { Rails.root.join('storage/fs') }

    it 'replaces all Store::Provider::{source} records with Store::Provider::{target} ones' do
      file # create Store::File record

      expect { described_class.move('DB', 'File') }
        .to change { file.reload.provider }.to('File')
        .and change(Store::Provider::DB, :count).by(-1)
        .and change { Dir[storage_path.join('**', '*')].select { |entry| File.file?(entry) }.count }.by(1)
    end

    context 'when no Store::File records of the source type exist' do
      it 'makes no changes and returns true' do
        file  # create Store::File record

        expect { described_class.move('File', 'DB') }
          .not_to change { file.reload.provider }
      end
    end

    context 'when moving from "File" adapter to "DB"' do
      before { Setting.set('storage_provider', 'File') }

      it 'removes stored files from filesystem' do
        file  # create Store::File record

        expect { described_class.move('File', 'DB') }
          .to change { file.reload.provider }.to('DB')
          .and change(Store::Provider::DB, :count).by(1)
          .and change { Dir[storage_path.join('*')].count }.by(-1)
      end
    end
  end

  describe '#update_checksum!' do
    let(:store)    { create(:store, :txt, data: 'foo') }
    let(:file)     { store.store_file }
    let(:new_data) { 'lorem ipsum' }

    context 'when checksum is already correct' do
      it 'does nothing' do
        expect { file.update_checksum! }.not_to change(file, :updated_at)
      end
    end

    context 'when checksum is incorrect' do
      let(:initial_sha) { file.sha }

      before do
        initial_sha

        Store::Provider::DB.find_by(sha: file.sha).update!(data: new_data)
      end

      it 'changes checksum to correct value' do
        expect { file.update_checksum! }.to change(file, :sha)
      end

      it 'calls .change_checksum on provider' do
        allow(Store::Provider::DB).to receive(:change_checksum)

        file.update_checksum!

        expect(Store::Provider::DB)
          .to have_received(:change_checksum)
          .with(initial_sha, described_class.checksum(new_data))
      end

      it 'updates size on related Store records' do
        expect { file.update_checksum! }
          .to change { store.reload.size }.to(new_data.bytesize.to_s)
      end
    end

    context 'when checksum is incorrect and another file with the new checksum already exists' do
      let(:other_store) { create(:store, :txt, data: new_data) }
      let(:other_file)  { other_store.store_file }

      before do
        file
        other_file

        Store::Provider::DB.find_by(sha: file.sha).update!(data: new_data)
      end

      it 'destroys the record' do
        expect { file.update_checksum! }
          .to change { described_class.exists?(file.id) }.to(false)
      end

      it 'points Store records to existing file' do
        expect { file.update_checksum! }
          .to change { store.reload.store_file }.to(other_file)
      end

      it 'updates size on related Store records' do
        expect { file.update_checksum! }
          .to change { store.reload.size }.to(new_data.bytesize.to_s)
      end
    end

    context 'when checksum is incorrect, another file with the new checksum already exists, but that file is also changed' do
      let(:other_store) { create(:store, :txt, data: new_data) }
      let(:other_file)  { other_store.store_file }

      before do
        file
        other_file

        Store::Provider::DB.find_by(sha: file.sha).update!(data: new_data)
        Store::Provider::DB.find_by(sha: other_file.sha).update!(data: 'yetanotherdatahere')
      end

      it 'does not destroy the record' do
        expect do
          begin begin
            file.update_checksum!
          rescue
            nil
          end
          end
        end
          .not_to change { described_class.exists?(file.id) }.from(true)
      end

      it 'does not touch Store records' do
        expect do
          begin begin
            file.update_checksum!
          rescue
            nil
          end
          end
        end
          .not_to change { store.reload.store_file }
      end

      it 'raises an error' do
        expect { file.update_checksum! }
          .to raise_error(%r{CONFLICT: file with SHA})
      end
    end
  end
end
