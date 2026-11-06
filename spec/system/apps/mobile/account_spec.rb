# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > App Account Page', app: :mobile, type: :playwright do
  describe 'language selection' do
    before do
      open_mobile('/account')
    end

    it 'user can change language' do
      page.get_by_role('combobox', name: 'Language').click
      page.get_by_role('dialog', name: 'Language').get_by_role('option', name: 'Deutsch - German').click

      expect(main_content).to contain_text('Sprache')
    end
  end

  describe 'avatar handling', authenticated_as: :agent do
    let(:agent)  { create(:agent, firstname: 'Jane', lastname: 'Doe') }
    let(:avatar) { main_content.get_by_role('img', name: 'Avatar (Jane Doe)', exact: true) }

    before do
      open_mobile('/account/avatar')
    end

    it 'user can upload avatar' do
      expect(avatar).to have_text('JD')

      file_chooser = page.expect_file_chooser { main_content.get_by_role('button', name: 'Library', exact: true).click }
      file_chooser.set_files(Rails.root.join('test/data/image/1000x1000.png').to_s)

      save = main_content.get_by_role('button', name: 'Save', exact: true)
      expect(save).to be_enabled
      save.click
      wait_for_mutation('userCurrentAvatarAdd')

      store   = Store.find(Avatar.last.store_resize_id)
      img_url = "data:#{store.preferences['Mime-Type']};base64,#{Base64.strict_encode64(store.content)}"

      expect(avatar).to have_css('background-image', "url(\"#{img_url}\")")
    end
  end
end
