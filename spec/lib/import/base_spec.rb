# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/import_job_backend_examples'

RSpec.describe Import::Base do
  it_behaves_like 'ImportJob backend'

  describe '#active?' do

    it 'returns true by default' do
      expect(described_class.active?).to be true
    end
  end

  describe '#queueable?' do

    it 'returns true by default' do
      expect(described_class.queueable?).to be true
    end
  end

  describe '.start' do

    it 'raises an error if called and not overwritten' do

      import_job = create(:import_job)
      instance   = described_class.new(import_job)

      expect do
        instance.start
      end.to raise_error(RuntimeError)
    end
  end

  describe '#reschedule?' do

    it 'returns false by default' do
      import_job  = create(:import_job)
      instance    = described_class.new(import_job)
      delayed_job = double()

      expect(instance.reschedule?(delayed_job)).to be false
    end
  end
end
