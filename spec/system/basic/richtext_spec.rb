# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Richtext', type: :system do

  before do
    visit '#layout_ref/richtext'
  end

  context 'Richtext' do

    it 'Single line mode' do

      element = find('#content .text-1')

      element.send_keys(
        'some test for browser ',
        :enter,
        'and some other for browser'
      )

      expect(element).to have_text('some test for browser and some other for browser')
    end

    it 'Multi line mode' do

      element = find('#content .text-5')

      element.send_keys(
        'some test for browser ',
        :enter,
        'and some other for browser'
      )

      expect(element).to have_text(%r{some test for browser\s?\nand some other for browser})
    end
  end

  context 'Regular text' do

    it 'Multi line mode' do

      element = find('#content .text-3')

      element.send_keys(
        'some test for browser ',
        :enter,
        'and some other for browser'
      )

      expect(element).to have_text(%r{some test for browser\s?\nand some other for browser})
    end
  end
end
