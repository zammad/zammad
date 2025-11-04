# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Tags', type: :system do
  before do
    visit 'manage/tags'
  end

  let(:tag_name) { 'New Tag 123' }

  # https://github.com/zammad/zammad/issues/4277
  it 'removes a tag after adding a tag without double modal' do
    within :active_content do
      find('input[name="name"]').fill_in with: tag_name
      click '.js-submit'
    end

    within '.js-Table tr', text: tag_name do
      click '.btn--secondary'
    end

    in_modal do
      click_on 'Yes'
    end

    expect(page).to have_no_css('.modal')
  end

  it 'adds multiple tags at once (#5795)' do
    within :active_content do
      find('input[name="name"]').fill_in with: 'tag1, tag2, tag3'
      click '.js-submit'
    end

    expect(page).to have_css('.js-Table tr', text: 'tag1')
    expect(page).to have_css('.js-Table tr', text: 'tag2')
    expect(page).to have_css('.js-Table tr', text: 'tag3')
    expect(Tag::Item.pluck(:name)).to include('tag1', 'tag2', 'tag3')
  end
end
