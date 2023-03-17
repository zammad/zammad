# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Assets', db_strategy: :reset, type: :system do
  let(:organization) { create(:organization, note: 'hello') }
  let(:customer)     { create(:customer, organization: organization, note: 'hello', last_login: Time.zone.now, login_failed: 1) }
  let(:agent) do
    user = create(:agent, groups: [Group.find_by(name: 'Users')], note: 'hello', last_login: Time.zone.now, login_failed: 1)
    create(:twitter_authorization, user: user)
    user
  end
  let(:admin)        { create(:admin, groups: [Group.find_by(name: 'Users')], note: 'hello', last_login: Time.zone.now, login_failed: 1) }
  let(:ticket)       { create(:ticket, owner: agent, group: Group.find_by(name: 'Users'), customer: customer, created_by: admin) }

  context 'groups' do
    before do
      visit '/'
    end

    def group_note
      page.execute_script('return App.Group.first().note')
    end

    describe 'when customer', authenticated_as: :customer do
      it 'can not access group details' do
        expect(group_note).to be_nil
      end
    end

    describe 'when agent', authenticated_as: :agent do
      it 'can access group details' do
        expect(group_note).not_to be_nil
      end
    end

    describe 'when admin', authenticated_as: :admin do
      it 'can access group details' do
        expect(group_note).not_to be_nil
      end
    end
  end

  context 'organizations' do
    def organization_note
      page.execute_script("return App.Organization.find(#{organization.id}).note")
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    describe 'when customer', authenticated_as: :customer do
      it 'can not access organization details' do
        expect(organization_note).to be_nil
      end
    end

    describe 'when agent', authenticated_as: :agent do
      it 'can access organization details' do
        expect(organization_note).not_to be_nil
      end
    end

    describe 'when admin', authenticated_as: :admin do
      it 'can access organization details' do
        expect(organization_note).not_to be_nil
      end
    end
  end

  context 'roles' do
    def role_name
      page.execute_script('return App.Role.first().name')
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    describe 'when customer', authenticated_as: :customer do
      it 'can not access role details' do
        expect(role_name).to eq('Role_1')
      end
    end

    describe 'when agent', authenticated_as: :agent do
      it 'can access role details' do
        expect(role_name).not_to eq('Role_1')
      end
    end

    describe 'when admin', authenticated_as: :admin do
      it 'can access role details' do
        expect(role_name).not_to eq('Role_1')
      end
    end
  end

  context 'users' do
    def customer_email
      page.execute_script("return App.User.find(#{customer.id}).email")
    end

    def customer_note
      page.execute_script("return App.User.find(#{customer.id}).note")
    end

    def owner_firstname
      page.execute_script("return App.User.find(#{agent.id}).firstname")
    end

    def owner_accounts
      page.execute_script("return App.User.find(#{agent.id}).accounts")
    end

    def owner_details
      [
        page.execute_script("return App.User.find(#{agent.id}).last_login"),
        page.execute_script("return App.User.find(#{agent.id}).login_failed"),
        page.execute_script("return App.User.find(#{agent.id}).email"),
        page.execute_script("return App.User.find(#{agent.id}).note"),
      ].compact
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    describe 'when customer', authenticated_as: :customer do
      it 'can access customer email' do
        expect(customer_email).not_to be_nil
      end

      it 'can not access customer note' do
        expect(customer_note).to be_nil
      end

      it 'can not access owner details' do
        expect(owner_details).to be_empty
      end

      it 'can access owner firstname' do
        expect(owner_firstname).not_to be_nil
      end

      it 'can access not owner owner accounts' do
        expect(owner_accounts).to be_nil
      end
    end

    describe 'when agent', authenticated_as: :agent do
      it 'can access customer email' do
        expect(customer_email).not_to be_nil
      end

      it 'can access customer note' do
        expect(customer_note).not_to be_nil
      end

      it 'can access owner details' do
        expect(owner_details).not_to be_empty
      end

      it 'can access owner firstname' do
        expect(owner_firstname).not_to be_nil
      end

      it 'can access owner owner accounts' do
        expect(owner_accounts).not_to be_nil
      end
    end

    describe 'when admin', authenticated_as: :admin do
      it 'can access customer email' do
        expect(customer_email).not_to be_nil
      end

      it 'can access customer note' do
        expect(customer_note).not_to be_nil
      end

      it 'can access owner details' do
        expect(owner_details).not_to be_empty
      end

      it 'can access owner firstname' do
        expect(owner_firstname).not_to be_nil
      end

      it 'can access owner owner accounts' do
        expect(owner_accounts).not_to be_nil
      end
    end
  end
end
