# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'ImportJob backend' do

  it 'requires an import job instance as parameter' do

    expect do
      described_class.new
    end.to raise_error(ArgumentError)

    import_job = create(:import_job)
    expect do
      described_class.new(import_job)
    end.not_to raise_error
  end
end
