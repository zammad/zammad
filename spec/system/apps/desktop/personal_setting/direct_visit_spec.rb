# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Personal Setting > Direct visit', app: :desktop_view, authenticated_as: :agent, type: :playwright do
  let(:agent) { create(:agent) }

  it 'redirects the personal settings root to the appearance page' do
    open_desktop('/personal-setting')

    expect(page).to have_url(%r{/desktop/personal-setting/appearance$})
    expect(main_content).to contain_text('Sync with computer')
  end
end
