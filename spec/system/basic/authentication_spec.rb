require 'rails_helper'

RSpec.describe 'Authentication', type: :system do

  it 'Login', authenticated_as: false do
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

  it 'will unset user attributes after logout' do
    logout
    expect_current_route 'login', wait: 2

    visit '/#signup'

    # check wrong displayed fields in registration form after logout. #2989
    expect(page).to have_no_selector('select[name=organization_id]')
  end
end
