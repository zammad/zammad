require 'rails_helper'

RSpec.describe 'Signup', type: :system, authenticated_as: false do
  it 'shows password strength error' do
    visit 'signup'

    fill_in 'firstname',        with: 'Test'
    fill_in 'lastname',         with: 'Test'
    fill_in 'email',            with: 'test@example.com'
    fill_in 'password',         with: 'badpw'
    fill_in 'password_confirm', with: 'badpw'

    click '.js-submit'

    expect(page).to have_text 'Invalid password,'
  end
end
