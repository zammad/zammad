# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue2429UserIdentifierValidation, type: :db_migration do
  let(:elem) { ObjectManager::Attribute.for_object(User).find_by(name: 'firstname') }

  it 'resets value directly in screen' do
    elem.screens = { screen1: { asd: true, null: false } }
    elem.save!

    migrate

    expect(elem.reload.screens).to eq({ screen1: { asd: true, null: true } }.deep_stringify_keys)
  end

  it 'resets value nested in permission' do
    elem.screens = { screen1: { all: { asd: true, null: false } } }
    elem.save!

    migrate

    expect(elem.reload.screens).to eq({ screen1: { all: { asd: true, null: true } } }.deep_stringify_keys)
  end

  it 'does not touch when null not present directly in screen' do
    elem.screens = { screen1: { all: { asd: true } } }
    elem.save!

    expect { migrate }.not_to change { elem.reload.updated_at }
  end

  it 'does not touch when null not present in permission' do
    elem.screens = { screen1: { asd: true } }
    elem.save!

    expect { migrate }.not_to change { elem.reload.updated_at }
  end
end
