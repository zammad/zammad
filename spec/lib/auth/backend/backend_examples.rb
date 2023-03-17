# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'Auth backend' do

  it 'responds to #valid?' do
    expect(instance).to respond_to(:valid?)
  end
end
