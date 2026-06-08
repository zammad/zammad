# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Zammad::Service::Configuration do
  describe '.template' do
    context 'when adapter is s3' do
      let(:adapter) { 's3' }

      before do
        described_class.instance_variable_set(:@adapter, adapter)
      end

      shared_examples 'parses and encodes access and secret keys correctly' do |result|
        it 'parses and decodes access and secret keys correctly' do
          parsed_result = described_class.send(:template, uri)

          expect(parsed_result).to eq(result)
        end
      end

      context 'with unencoded values' do
        let(:uri) { URI.parse('http://zammadadmin:zammadadmin@localhost/zammad?region=us-east-1&force_path_style=true') }

        it_behaves_like 'parses and encodes access and secret keys correctly', {
          bucket:            'zammad',
          endpoint:          'http://localhost:80',
          access_key_id:     'zammadadmin',
          secret_access_key: 'zammadadmin'
        }
      end

      context 'with encoded values' do
        let(:uri) { URI.parse('http://zammad%2Fadmin:zammad%2Fadmin@localhost/zammad?region=us-east-1&force_path_style=true') }

        it_behaves_like 'parses and encodes access and secret keys correctly', {
          bucket:            'zammad',
          endpoint:          'http://localhost:80',
          access_key_id:     'zammad/admin',
          secret_access_key: 'zammad/admin'
        }
      end

      context 'with empty values for access_key_id and secret_access_key' do
        let(:uri) { URI.parse('http://:@localhost/') }

        it_behaves_like 'parses and encodes access and secret keys correctly', {
          bucket:            '',
          endpoint:          'http://localhost:80',
          access_key_id:     nil,
          secret_access_key: nil
        }
      end
    end
  end
end
