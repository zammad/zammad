# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::StorageProvider do

  let(:setting_name) { 'storage_provider' }

  context 'with blank settings' do
    it 'does not raise an error' do
      expect { Setting.set(setting_name, {}) }.not_to raise_error
    end
  end

  context 'with using DB as storage provider' do
    it 'does not raise an error' do
      expect { Setting.set(setting_name, 'DB') }.not_to raise_error
    end
  end

  context 'with using S3 as storage provider' do

    before do
      ENV.delete('S3_URL') if ENV['CI']
      Store::Provider::S3.reset
    end

    context 'when no config is present' do
      it 'does raise an error' do
        expect { Setting.set(setting_name, 'S3') }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Simple Storage Service not reachable.')
      end
    end

    context 'when endpoint is not reachable' do
      before do
        ENV['S3_URL'] = 'https://s3.eu-central-1.zammad.org/zammad-storage-bucket?region=eu-central-1&force_path_style=true'
      end

      it 'does raise an error' do
        expect { Setting.set(setting_name, 'S3') }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Simple Storage Service not reachable.')
      end
    end

    context 'with invalid S3_URL environment variable' do
      before do
        ENV['S3_URL'] = 'https://key:secret@s3.eu-central-1.amazonaws.com/zammad-storage-bucket'
      end

      it 'does raise an error' do
        expect { Setting.set(setting_name, 'S3') }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Simple Storage Service not reachable.')
      end
    end
  end
end
