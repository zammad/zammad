# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ApplicationController::HasDownload::TempfileBody do
  subject(:body) { described_class.new(file) }

  let(:file) { Tempfile.new.tap { |tempfile| tempfile.write('some content') } }

  after { file.close! }

  it 'does not expose a path or an array, so Rack middlewares do not buffer it' do
    expect(body).not_to respond_to(:to_path, :to_ary)
  end

  describe '#each' do
    before { stub_const("#{described_class}::CHUNK_SIZE", 5) }

    it 'yields the content of the file in chunks from its beginning' do
      expect { |block| body.each(&block) }.to yield_successive_args('some ', 'conte', 'nt')
    end
  end

  describe '#close' do
    it 'closes the file' do
      expect { body.close }.to change(file, :closed?).to(true)
    end
  end
end
