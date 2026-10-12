# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::BaseFactory do
  let(:backend) { Class.new { def initialize(*); end } }
  let(:factory) { Module.new { extend Import::BaseFactory } }

  before do
    stub_const('Import::Sample', backend)
    stub_const('Import::SampleFactory', factory)
  end

  describe '.import' do
    it 'requires an implementation' do
      expect { factory.import([]) }.to raise_error(RuntimeError, 'Missing import method implementation for this factory')
    end
  end

  describe '.backend_class' do
    it 'derives the backend class from the factory name' do
      expect(factory.backend_class({})).to eq(Import::Sample)
    end
  end

  describe '.skip?' do
    it 'skips no record by default' do
      expect(factory.skip?({})).to be false
    end
  end

  describe '.import_action' do
    let(:records) { [{ 'id' => 1 }, { 'id' => 2 }] }

    before do
      allow(backend).to receive(:new).and_call_original
      allow(factory).to receive_messages(pre_import_hook: nil, post_import_hook: nil, post_all_import_hook: nil)
    end

    it 'creates a backend instance for each record and calls the hooks', :aggregate_failures do
      factory.import_action(records, 'extra')

      expect(factory).to have_received(:pre_import_hook).with(records, 'extra').once
      records.each do |record|
        expect(backend).to have_received(:new).with(record, 'extra')
        expect(factory).to have_received(:post_import_hook).with(record, kind_of(backend), 'extra')
      end
      expect(factory).to have_received(:post_all_import_hook).once
    end

    it 'does not create backend instances for skipped records', :aggregate_failures do
      allow(factory).to receive(:skip?) { |record| record['id'] == 1 }

      factory.import_action(records)

      expect(backend).to have_received(:new).once
      expect(backend).to have_received(:new).with(records.last)
      expect(factory).to have_received(:post_import_hook).once
    end

    it 'calls the post all import hook even if the import fails', :aggregate_failures do
      allow(backend).to receive(:new).and_raise(RuntimeError)

      expect { factory.import_action(records) }.to raise_error(RuntimeError)
      expect(factory).to have_received(:post_all_import_hook).once
    end
  end
end
