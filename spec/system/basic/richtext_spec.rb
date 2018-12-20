require 'rails_helper'

RSpec.describe 'Richtext', type: :system do

  before(:each) do
    click(:href, '#current_user')
    click(:href, '#layout_ref')
    click(:href, '#layout_ref/richtext')
  end

  context 'Richtext' do

    scenario 'Single line mode' do

      element = find('#content .text-1')

      element.send_keys(
        'some test for browser ',
        :enter,
        'and some other for browser'
      )

      expect(element).to have_content('some test for browser and some other for browser')
    end

    scenario 'Multi line mode' do

      element = find('#content .text-5')

      element.send_keys(
        'some test for browser ',
        :enter,
        'and some other for browser'
      )

      expect(element).to have_content("some test for browser \nand some other for browser")
    end
  end

  context 'Regular text' do

    scenario 'Multi line mode' do

      element = find('#content .text-3')

      element.send_keys(
        'some test for browser ',
        :enter,
        'and some other for browser'
      )

      expect(element).to have_content("some test for browser \nand some other for browser")
    end
  end
end
