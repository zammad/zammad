# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > App Account Page', app: :mobile, type: :system do
  describe 'language selection' do
    before do
      visit '/account'
    end

    it 'user can change language' do
      locale = find_treeselect('Language')
      locale.select_option('Deutsch')
      expect(page).to have_text('Sprache')
    end
  end

  describe 'avatar handling', authenticated_as: :agent do
    let(:agent) { create(:agent, firstname: 'Jane', lastname: 'Doe') }

    before do
      visit '/account/avatar'
    end

    it 'user can upload avatar' do
      expect(page).to have_text('JD')
      find('input[data-test-id="fileGalleryInput"]', visible: :all).set(Rails.root.join('test/data/image/1000x1000.png'))

      expect(page).to have_css('.vue-advanced-cropper')
      click_on 'Save'

      wait.until { Avatar.last.present? }
      store   = Store.find(Avatar.last.store_resize_id)
      img_url = "data:#{store.preferences['Mime-Type']};base64,#{Base64.strict_encode64(store.content)}"

      avatar_element_style = find('[data-test-id="common-avatar"]').style('background-image')
      expect(avatar_element_style['background-image']).to eq("url(\"#{img_url}\")")
    end
  end
end
