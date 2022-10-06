# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Auto Assignment', type: :system do
  describe 'Core functionality', authenticated_as: :authenticate do
    let!(:ticket)       { create(:ticket, group: Group.find_by(name: 'Users'), state: Ticket::State.find_by(name: 'new')) }
    let!(:session_user) { User.find_by(login: 'admin@example.com') }

    context 'when agent disabled' do
      def authenticate
        Setting.set('ticket_auto_assignment', false)
        Setting.set('ticket_auto_assignment_selector', { condition: { 'ticket.state_id' => { operator: 'is', value: Ticket::State.by_category(:work_on).pluck(:id) } } })
        Setting.set('ticket_auto_assignment_user_ids_ignore', [])

        true
      end

      it 'do not assign ticket to current session user' do
        visit "#ticket/zoom/#{ticket.id}"

        within(:active_content) do
          expect(page).to have_select('owner_id',
                                      selected: '-',
                                      options:  ['-', 'Agent 1 Test', 'Test Admin Agent'])
        end
      end
    end

    context 'when agent enabled' do
      def authenticate
        Setting.set('ticket_auto_assignment', true)
        Setting.set('ticket_auto_assignment_selector', { condition: { 'ticket.state_id' => { operator: 'is', value: Ticket::State.by_category(:work_on).pluck(:id) } } })
        Setting.set('ticket_auto_assignment_user_ids_ignore', setting_user_ids_ignore) if defined?(setting_user_ids_ignore)

        true
      end

      context 'with empty "ticket_auto_assignment_user_ids_ignore"' do
        it 'assigns ticket to current session user' do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            expect(page).to have_css('.content.active select[name=owner_id]')
            expect(page).to have_select('owner_id',
                                        selected: session_user.fullname,
                                        options:  ['-', 'Agent 1 Test', 'Test Admin Agent'])
          end
        end
      end

      context 'with "ticket_auto_assignment_user_ids_ignore" (as integer)' do
        let(:setting_user_ids_ignore) { session_user.id }

        it 'assigns ticket not to current session user' do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            expect(page).to have_select('owner_id',
                                        selected: '-',
                                        options:  ['-', 'Agent 1 Test', 'Test Admin Agent'])
          end
        end
      end

      context 'with "ticket_auto_assignment_user_ids_ignore" (as string)' do
        let(:setting_user_ids_ignore) { session_user.id.to_s }

        it 'assigns ticket not to current session user' do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            expect(page).to have_select('owner_id',
                                        selected: '-',
                                        options:  ['-', 'Agent 1 Test', 'Test Admin Agent'])
          end
        end
      end

      context 'with "ticket_auto_assignment_user_ids_ignore" (as [integer])' do
        let(:setting_user_ids_ignore) { [session_user.id] }

        it 'assigns ticket not to current session user' do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            expect(page).to have_select('owner_id',
                                        selected: '-',
                                        options:  ['-', 'Agent 1 Test', 'Test Admin Agent'])
          end
        end
      end

      context 'with "ticket_auto_assignment_user_ids_ignore" (as [string])' do
        let(:setting_user_ids_ignore) { [session_user.id.to_s] }

        it 'assigns ticket not to current session user' do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            expect(page).to have_select('owner_id',
                                        selected: '-',
                                        options:  ['-', 'Agent 1 Test', 'Test Admin Agent'])
          end
        end
      end

      context 'with "ticket_auto_assignment_user_ids_ignore" and other user ids' do
        let(:setting_user_ids_ignore) { [99_999, 999_999] }

        it 'assigns ticket to current session user' do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            expect(page).to have_select('owner_id',
                                        selected: session_user.fullname,
                                        options:  ['-', 'Agent 1 Test', 'Test Admin Agent'])
          end
        end
      end
    end
  end

  describe 'Mandatory field in combination with automatic assignment leads to a divergence in the setting of the ticket owner #4245', authenticated_as: :authenticate, db_strategy: :reset do
    let!(:ticket)    { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:field_name) { SecureRandom.uuid }
    let(:field) do
      create :object_manager_attribute_text, name: field_name, display: field_name, screens: attributes_for(:required_screen)
      ObjectManager::Attribute.migration_execute
    end

    def authenticate
      Setting.set('ticket_auto_assignment', true)
      Setting.set('ticket_auto_assignment_selector', { condition: { 'ticket.state_id' => { operator: 'is', value: Ticket::State.all.pluck(:id) } } })
      field
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does auto assign the current user even if we have an empty required field' do
      expect(page).to have_select('owner_id', selected: 'Test Admin Agent')
    end
  end
end
