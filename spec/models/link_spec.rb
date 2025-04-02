# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Link, type: :model do
  subject(:link) { create(:link) }

  it 'can be saved' do
    expect(link).to be_persisted
  end

  it 'Validates link uniqueness' do
    link # create a matching link

    other = build(:link)
    other.save

    expect(other.errors.full_messages).to include('Link already exists')
  end
end
