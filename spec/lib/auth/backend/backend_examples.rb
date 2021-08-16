# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'Auth backend' do

  it 'responds to #valid?' do
    expect(instance).to respond_to(:valid?)
  end
end
