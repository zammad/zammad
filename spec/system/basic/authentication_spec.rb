require 'rails_helper'

RSpec.describe 'Authentication', type: :system do

  it 'Login', authenticated: false do
    login(
      username: 'master@example.com',
      password: 'test',
    )

    expect_current_route 'dashboard'
  end

  it 'Logout' do
    logout
    expect_current_route 'login', wait: 2
  end
end
