# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Admin Password Auth', app: :desktop_view, authenticated_as: false, type: :playwright do
  let(:username) { page.get_by_label('Username / Email') }
  let(:password) { page.get_by_label('Password') }

  before do
    Setting.set('user_show_password_login', false)
    Setting.set('auth_github', true)
  end

  it 'Shows the regular password login after admin password auth request was sent' do
    open_desktop('/login')

    request = page.get_by_role('link', name: 'Request the password login here.')
    expect(request).to be_visible
    expect(username).to have_count(0)
    expect(password).to have_count(0)

    request.click

    fill_field('Username / Email', 'admin@example.com')
    page.get_by_role('button', name: 'Submit', exact: true).click

    expect(main_content).to contain_text('Admin password login instructions were sent')

    open_desktop("/login?token=#{Token.last.token}")

    expect(main_content).to contain_text('The token is valid. You are now able to login via password once.')
    expect(username).to be_visible
    expect(password).to be_visible
  end
end
