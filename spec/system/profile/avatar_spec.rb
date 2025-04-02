# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Profile > Avatar', type: :system do
  let(:image) { Rails.root.join('spec/fixtures/files/image/squares.png') }

  before do
    visit '#profile/avatar'
  end

  it 'can re-upload the same image afterwards (#5456)' do
    within :active_content do
      # Upload an image.
      find('input.js-upload', visible: :all).set(image)
    end

    in_modal do
      click_on 'Save'
    end

    within :active_content do
      # Simulate hover to make the delete button visible and click on it.
      page.execute_script("$('.avatar-delete').css('visibility', 'visible').click()")

      prompt = page.driver.browser.switch_to.alert
      prompt.accept

      await_empty_ajax_queue

      # The input should be empty now.
      expect(find('input.js-upload', visible: :all).value).to be_empty

      # Re-upload the same image.
      find('input.js-upload', visible: :all).set(image)
    end

    in_modal do
      click_on 'Save'
    end

    within :active_content do
      expect(page).to have_css('.avatar-holder .avatar')
    end
  end
end
