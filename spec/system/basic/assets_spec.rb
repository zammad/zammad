# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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

    def group_name_last
      page.execute_script('return App.Group.first().name_last')
    end

    def group_parent_id
      page.execute_script('return App.Group.first().parent_id')
    end

    describe 'when customer', authenticated_as: :customer do
      it 'can not access group details' do
        expect(group_note).to be_nil
      end

      it 'can access name_last attribute (#4981)' do
        expect(group_name_last).not_to be_nil
      end

      context 'when group has parent', authenticated_as: :authenticate do
        def authenticate
          Group.first.update(parent_id: create(:group, name: 'Parent').id)

          customer
        end

        it 'can access parent_id attribute' do
          expect(group_parent_id).not_to be_nil
        end
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

    def customer_available_group_count
      page.execute_script('return App.Group.all().length')
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

    describe 'when customer', authenticated_as: :customer do
      let(:agent_groups) { create_list(:group, 3) }

      context 'when zoom' do
        before do
          visit "#ticket/zoom/#{ticket.id}"
        end

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

        context 'when groups are restricted', authenticated_as: :authenticate do
          def authenticate
            agent_groups
            Setting.set('customer_ticket_create_group_ids', [Group.first.id])
            customer
          end

          it 'can not access agent groups' do
            expect(customer_available_group_count).to eq(1)
          end

          context 'when there are old tickets for the customer', authenticated_as: :authenticate do
            def authenticate
              agent_groups
              create(:ticket, group: agent_groups.first, customer: customer)
              Setting.set('customer_ticket_create_group_ids', [Group.first.id])
              customer
            end

            it 'can access one of the agent groups' do
              expect(customer_available_group_count).to eq(2)
            end
          end
        end
      end

      context 'when ticket create' do
        before do
          visit '#customer_ticket_new'
        end

        context 'when there are no customer groups', authenticated_as: :authenticate do
          def authenticate
            agent_groups
            Setting.set('customer_ticket_create_group_ids', [])
            customer
          end

          it 'can create tickets in all groups' do
            expect(customer_available_group_count).to eq(5)
          end
        end

        context 'when there are customer groups', authenticated_as: :authenticate do
          def authenticate
            agent_groups
            Setting.set('customer_ticket_create_group_ids', [Group.first.id])
            customer
          end

          it 'can create tickets in configured groups' do
            expect(customer_available_group_count).to eq(1)
          end
        end
      end
    end

    describe 'when agent', authenticated_as: :agent do
      before do
        visit "#ticket/zoom/#{ticket.id}"
      end

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
      before do
        visit "#ticket/zoom/#{ticket.id}"
      end

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
