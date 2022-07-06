# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > App Home Page', type: :system, app: :mobile do
  context 'when on the home page', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    before do
      visit '/'
    end

    # TODO: align test, when we have the real funtionality on the home page (with correct permissions).
    it 'check that we are on the home page' do
      expect(page).to have_text('Home')
    end
  end
end
