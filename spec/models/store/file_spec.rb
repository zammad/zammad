# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

  describe '.verify' do
    context 'when no Store::File records exist' do
      it 'returns true' do
        expect(described_class.verify).to be(true)
      end
    end

    context 'when all Store::File records have matching #content / #sha attributes' do
      before do
        file # create Store::File record
      end

      it 'returns true' do
        expect(described_class.verify).to be(true)
      end
    end

    context 'when at least one Store::File record’s #content / #sha attributes do not match' do
      before do
        file # create Store::File record
        Store::Provider::DB.last.update(data: 'bar')
      end

      it 'returns false' do
        expect(described_class.verify).to be(false)
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
end
