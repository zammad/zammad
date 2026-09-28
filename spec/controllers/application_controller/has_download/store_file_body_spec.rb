# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ApplicationController::HasDownload::StoreFileBody do
  subject(:body) { described_class.new(store_file) }

  let(:store_file) { Store::File.add('some content') }

  it 'does not expose a path or an array, so Rack middlewares do not buffer it' do
    expect(body).not_to respond_to(:to_path, :to_ary)
  end

  describe '#each' do
    it 'yields the content of the file' do
      expect { |block| body.each(&block) }.to yield_with_args('some content')
    end

    context 'when writing to the client fails' do
      before { allow(Rails.logger).to receive(:error) }

      let(:failing_client) { ->(_chunk) { raise IOError } }

      it 'does not log it as a streaming failure', :aggregate_failures do
        expect { body.each(&failing_client) }.to raise_error(IOError)
        expect(Rails.logger).not_to have_received(:error)
      end
    end

    context 'when streaming fails' do
      before do
        allow(store_file).to receive(:stream).and_raise(Errno::ENOENT)
        allow(Rails.logger).to receive(:error)
      end

      it 'logs and re-raises the error', :aggregate_failures do
        expect { body.each { nil } }.to raise_error(Errno::ENOENT)
        expect(Rails.logger).to have_received(:error).with(%r{Streaming of Store::File #{store_file.id} failed})
      end
    end
  end
end
