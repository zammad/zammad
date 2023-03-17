# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Account > Avatar', app: :mobile, type: :system do
  let(:agent) { create(:agent, firstname: 'Jane', lastname: 'Doe') }

  context 'when on Account > Avatar page', authenticated_as: :agent do
    let(:initial_buttons) do
      [
        {
          name:     'Library',
          disabled: false,
        },
        {
          name:     'Camera',
          disabled: false,
        },
        {
          name:     'Delete',
          disabled: true,
        },
      ]
    end

    before do
      visit '/account/avatar'
    end

    def wait_for_avatar
      wait.until do
        expect(page).to have_css('[data-test-id="common-avatar"]')
        expect(page).to have_button('Library')
      end
    end

    context 'when initial state is checked' do
      it 'shows the initials of the agent' do
        wait_for_avatar

        expect(find('[data-test-id="common-avatar"]')).to have_text('JD')
      end

      it 'shows buttons for uploading + deleting avatars' do
        wait_for_avatar

        initial_buttons.each do |button|
          expect(page).to have_button(button[:name], disabled: button[:disabled])
        end
      end
    end

    context 'when a new avatar is uploaded' do
      it 'can upload a new avatar' do
        wait_for_avatar

        expect(page).to have_no_button('Save')

        find('input[data-test-id="fileGalleryInput"]', visible: :all).set(Rails.root.join('test/data/image/1000x1000.png'))

        wait.until do
          expect(page).to have_button('Save')
        end

        find_button('Save').click

        wait.until do
          expect(page).to have_no_button('Save')
          expect(page).to have_button('Delete', disabled: false)
        end

        store   = Store.find(Avatar.last.store_resize_id)
        img_url = "data:#{store.preferences['Mime-Type']};base64,#{Base64.strict_encode64(store.content)}"

        avatar_element_style = find('[data-test-id="common-avatar"]').style('background-image')
        expect(avatar_element_style['background-image']).to eq("url(\"#{img_url}\")")
      end
    end

    context 'when an avatar is already uploaded' do
      let(:base64_img) { Base64.decode64(Rails.root.join('test/data/image/1000x1000.png').read) }

      let(:avatar) do
        avatar = Avatar.add(
          object:        'User',
          o_id:          agent.id,
          full:          {
            content:   base64_img,
            mime_type: 'image/png',
          },
          resize:        {
            content:   base64_img,
            mime_type: 'image/png',
          },
          source:        "upload #{Time.zone.now}",
          deletable:     true,
          created_by_id: agent.id,
          updated_by_id: agent.id,
        )
        agent.update!(image: avatar.store_hash)
        avatar
      end

      let(:background_image) do
        store = Store.find(avatar.store_resize_id)
        "data:#{store.preferences['Mime-Type']};base64,#{Base64.strict_encode64(store.content)}"
      end

      before do
        avatar
        visit '/account/avatar'
      end

      it 'displays the avatar' do
        avatar_element_style = find('[data-test-id="common-avatar"]').style('background-image')
        expect(avatar_element_style['background-image']).to eq("url(\"#{background_image}\")")
      end

      it 'displays the avatar in the footer' do
        visit '/account'

        avatar_element_style = find('footer [data-test-id="common-avatar"]').style('background-image')
        background_image_api_url = "/api/v1/users/image/#{avatar.store_hash}"

        expect(avatar_element_style['background-image']).to match(%r{#{background_image_api_url}})
      end

      it 'can delete an existing avatar' do
        wait.until do
          expect(page).to have_css('[data-test-id="common-avatar"]')
          expect(page).to have_button('Delete', disabled: false)
        end

        find_button('Delete').click

        wait.until do
          expect(page).to have_button('Delete avatar')
        end

        find_button('Delete avatar').click

        expect(find('[data-test-id="common-avatar"]')).to have_text('JD')
        expect(page).to have_button('Delete', disabled: true)
      end
    end
  end
end
