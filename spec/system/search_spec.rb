# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Search', type: :system, authenticated: true, searchindex: true do
  before do
    configure_elasticsearch(required: true, rebuild: true)
  end

  it 'shows default widgets' do
    fill_in id: 'global-search', with: '"Welcome"'

    click_on 'Show Search Details'

    within '#navigation .tasks a[data-key=Search]' do
      expect(page).to have_text '"Welcome"'
    end
  end
end
