require 'rails_helper'

RSpec.describe 'Manage > Users', type: :system do
  describe 'switching to an alternative user', authenticated_as: -> { original_user } do
    let(:original_user) { create(:admin) }
    let(:alternative_one_user) { create(:admin) }
    let(:alternative_two_user) { create(:admin) }

    before do
      alternative_one_user
      alternative_two_user
    end

    it 'starts as original user' do
      expect(current_user).to eq original_user
    end

    it 'switches to alternative user' do
      switch_to(alternative_one_user)
      expect(current_user).to eq alternative_one_user
    end

    it 'switches to another alternative user' do
      switch_to(alternative_one_user)
      switch_to(alternative_two_user)

      expect(current_user).to eq alternative_two_user
    end

    it 'switches back to original user' do
      switch_to(alternative_one_user)
      switch_to(alternative_two_user)

      click '.switchBackToUser-close'

      expect(current_user).to eq original_user
    end

    def switch_to(user)
      visit 'manage/users'

      within(:active_content) do
        row = find("tr[data-id=\"#{user.id}\"]")
        row.find('.js-action').click
        row.find('.js-switchTo').click
      end

      await_empty_ajax_queue
    end
  end

  describe 'check user edit permissions', authenticated_as: -> { user } do

    shared_examples 'user permission' do |allow|
      it(allow ? 'allows editing' : 'forbids editing') do
        visit "#user/profile/#{record.id}"
        find('.js-action .icon-arrow-down').click
        selector = '.js-action [data-type="edit"]'
        expect(page).to(allow ? have_css(selector) : have_no_css(selector))
      end
    end

    context 'when admin tries to change admin' do
      let(:user) { create(:admin) }
      let(:record) { create(:admin) }

      include_examples 'user permission', true
    end

    context 'when admin tries to change agent' do
      let(:user) { create(:admin) }
      let(:record) { create(:agent) }

      include_examples 'user permission', true
    end

    context 'when admin tries to change customer' do
      let(:user) { create(:admin) }
      let(:record) { create(:customer) }

      include_examples 'user permission', true
    end

    context 'when agent tries to change admin' do
      let(:user) { create(:agent) }
      let(:record) { create(:admin) }

      include_examples 'user permission', false
    end

    context 'when agent tries to change agent' do
      let(:user) { create(:agent) }
      let(:record) { create(:agent) }

      include_examples 'user permission', false
    end

    context 'when agent tries to change customer' do
      let(:user) { create(:agent) }
      let(:record) { create(:customer) }

      include_examples 'user permission', true
    end

    context 'when agent tries to change customer who is also admin' do
      let(:user) { create(:agent) }
      let(:record) { create(:customer, role_ids: Role.signup_role_ids.push(Role.find_by(name: 'Admin').id)) }

      include_examples 'user permission', false
    end

    context 'when agent tries to change customer who is also agent' do
      let(:user) { create(:agent) }
      let(:record) { create(:customer, role_ids: Role.signup_role_ids.push(Role.find_by(name: 'Agent').id)) }

      include_examples 'user permission', false
    end

  end
end
