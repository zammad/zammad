# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'ImportJob backend' do

  it 'responds to .queueable?' do
    expect(described_class).to respond_to(:queueable?)
  end

  it 'requires an import job instance as parameter' do

    expect do
      described_class.new
    end.to raise_error(ArgumentError)

    import_job = create(:import_job)
    expect do
      described_class.new(import_job)
    end.not_to raise_error
  end

  it 'responds to #start' do
    import_job = create(:import_job)
    expect(described_class.new(import_job)).to respond_to(:start)
  end

  it 'responds to #reschedule?' do
    import_job = create(:import_job)
    expect(described_class.new(import_job)).to respond_to(:reschedule?)
  end
end
