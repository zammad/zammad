# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_context 'factory' do # rubocop:disable RSpec/ContextWording
  it 'saves successfully' do
    expect(subject).to be_persisted # rubocop:disable RSpec/NamedSubject
  end
end
