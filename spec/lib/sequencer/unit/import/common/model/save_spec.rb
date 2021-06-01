# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::Model::Save, sequencer: :unit do
  let(:user) { instance_double('User') }

  before { allow(user).to receive(:save!) }

  context 'for action: :created' do
    it 'calls #save!' do
      process(action: :created, instance: user, dry_run: false)

      expect(user).to have_received(:save!)
    end
  end

  context 'for action: :updated' do
    it 'calls #save!' do
      process(action: :updated, instance: user, dry_run: false)

      expect(user).to have_received(:save!)
    end
  end

  context 'for action: :unchanged' do
    it 'avoids calling #save!' do
      process(action: :unchanged, instance: user, dry_run: false)

      expect(user).not_to have_received(:save!)
    end
  end

  context 'for action: :skipped' do
    it 'avoids calling #save!' do
      process(action: :skipped, instance: user, dry_run: false)

      expect(user).not_to have_received(:save!)
    end
  end

  context 'for action: :failed' do
    it 'avoids calling #save!' do
      process(action: :failed, instance: user, dry_run: false)

      expect(user).not_to have_received(:save!)
    end
  end

  context 'for BulkImportInfo flag' do

    it 'enables BulkImportInfo' do
      expect(BulkImportInfo).to receive(:enable)
      process(action: :created, instance: user, dry_run: false)
    end

    it 'ensures BulkImportInfo is disabled' do
      expect(BulkImportInfo).to receive(:disable)
      process(action: :created, instance: user, dry_run: false)
    end
  end
end
