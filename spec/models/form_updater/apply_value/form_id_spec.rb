# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormUpdater::ApplyValue::FormId, type: :model do
  subject(:apply_value) { FormUpdater::ApplyValue.new(context:, data:, result:) }

  let(:user)    { create(:agent) }
  let(:context) { { current_user: user } }
  let(:data)    { {} }
  let(:result)  { {} }
  let(:form_id) { SecureRandom.uuid }

  before do
    UserInfo.with_user_id(user.id) do
      UploadCache.new(form_id).add(
        data:        Rails.root.join('spec/fixtures/files/image/squares.png').binread,
        filename:    'squares.png',
        preferences: { 'Content-Type' => 'image/png' },
      )
    end
  end

  def perform(config)
    apply_value.perform(field: 'form_id', config: config)
  end

  it 'maps the cached files onto the attachments field' do
    perform({ 'value' => form_id })

    expect(result.dig('attachments', :value)).to include(include(name: 'squares.png'))
  end

  # The default, because most callers seed content the user has to be able to save afterwards: a
  #   ticket template, a shared draft, a split article. Those must leave the form dirty.
  it 'maps them as a plain value by default' do
    perform({ 'value' => form_id })

    expect(result['attachments']).not_to have_key(:initialValue)
  end

  # The opt-in, for a cache seeded from the record the form is editing - there the files are what
  #   the form opens with, so they have to be its baseline. Without this the file field has no
  #   `_init` and reads as changed before anybody touched it.
  context 'with as_initial' do
    it 'maps them as the field baseline instead', :aggregate_failures do
      perform({ 'value' => form_id, 'as_initial' => true })

      expect(result.dig('attachments', :initialValue)).to include(include(name: 'squares.png'))
      expect(result['attachments']).not_to have_key(:value)
    end
  end

  it 'skips inline files, which belong to the body rather than to the field' do
    UserInfo.with_user_id(user.id) do
      UploadCache.new(form_id).add(
        data:        Rails.root.join('spec/fixtures/files/image/squares.png').binread,
        filename:    'inline.png',
        preferences: { 'Content-Type' => 'image/png', 'Content-Disposition' => 'inline' },
      )
    end

    perform({ 'value' => form_id })

    expect(result.dig('attachments', :value).pluck(:name)).to eq(['squares.png'])
  end
end
