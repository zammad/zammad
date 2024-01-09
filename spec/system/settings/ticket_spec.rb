# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Settings > Ticket', type: :system do

  before { visit 'settings/ticket' }

  shared_examples 'switching setting on and off' do |section_name, setting_name|
    it "switches #{setting_name} setting on and off" do
      within(:active_content) do
        click(:href, "##{section_name}")
        expect(page).to have_field(setting_name, checked: false, visible: :hidden)
        click "label[for=\"#{setting_name}\"]"
        expect(page).to have_field(setting_name, checked: true, visible: :hidden)
      end

      refresh

      within(:active_content) do
        click(:href, "##{section_name}")
        expect(page).to have_field(setting_name, checked: true, visible: :hidden)
        click "label[for=\"#{setting_name}\"]"
        expect(page).to have_field(setting_name, checked: false, visible: :hidden)
      end
    end
  end

  describe 'Auto Assignment' do
    it_behaves_like 'switching setting on and off', 'auto_assignment', 'ticket_auto_assignment'
  end

  describe 'Duplicate Detection' do
    it_behaves_like 'switching setting on and off', 'duplicate_detection', 'ticket_duplicate_detection'
  end

  describe 'default agent notifications' do
    it 'check if default agent notifications are set' do
      within(:active_content) do
        click(:href, '#notification')

        default_agent_notifications = Setting.get('ticket_agent_default_notifications')

        default_agent_notifications.each do |key, value|
          expect(page).to have_field("matrix.#{key}.criteria.owned_by_me", checked: value[:criteria][:owned_by_me], visible: :all)
          expect(page).to have_field("matrix.#{key}.criteria.owned_by_nobody", checked: value[:criteria][:owned_by_nobody], visible: :all)
          expect(page).to have_field("matrix.#{key}.criteria.subscribed", checked: value[:criteria][:subscribed], visible: :all)
          expect(page).to have_field("matrix.#{key}.criteria.no", checked: value[:criteria][:no], visible: :all)
          expect(page).to have_field("matrix.#{key}.channel", checked: value[:channel][:email], visible: :all)
        end
      end
    end

    it 'updates default agent notifications' do
      within(:active_content) do
        click(:href, '#notification')

        expect(page).to have_field('matrix.escalation.criteria.owned_by_me', checked: true, visible: :all)

        find('input[name="matrix.escalation.criteria.owned_by_me"]', visible: :all).click
        find('input[name="matrix.escalation.channel"]', visible: :all).click

        find('.js-ticketDefaultNotifications').click

        await_empty_ajax_queue

        expect(Setting.get('ticket_agent_default_notifications')).to include(
          escalation: include(
            criteria: include(owned_by_me: false),
            channel:  include(email: false, online: true)
          ),
          update:     include(
            criteria: include(owned_by_me: true),
            channel:  include(email: true, online: true)
          )
        )
      end
    end

    context 'with already changed default agent notifications setting', authenticated_as: :setup_and_authenticate do
      let(:admin) { create(:admin) }

      def setup_and_authenticate
        Setting.set('ticket_agent_default_notifications', {
                      create:           {
                        criteria: {
                          owned_by_me:     true,
                          owned_by_nobody: false,
                          subscribed:      false,
                          no:              false,
                        },
                        channel:  {
                          email:  true,
                          online: true,
                        }
                      },
                      update:           {
                        criteria: {
                          owned_by_me:     true,
                          owned_by_nobody: false,
                          subscribed:      false,
                          no:              false,
                        },
                        channel:  {
                          email:  true,
                          online: true,
                        }
                      },
                      reminder_reached: {
                        criteria: {
                          owned_by_me:     true,
                          owned_by_nobody: false,
                          subscribed:      false,
                          no:              false,
                        },
                        channel:  {
                          email:  true,
                          online: true,
                        }
                      },
                      escalation:       {
                        criteria: {
                          owned_by_me:     true,
                          owned_by_nobody: false,
                          subscribed:      false,
                          no:              false,
                        },
                        channel:  {
                          email:  true,
                          online: true,
                        }
                      }
                    })

        admin
      end

      it 'reset to initial default agent notifications' do
        within(:active_content) do
          click(:href, '#notification')

          current_agent_notifications = Setting.get('ticket_agent_default_notifications')

          current_agent_notifications.each do |key, value|
            expect(page).to have_field("matrix.#{key}.criteria.owned_by_me", checked: value[:criteria][:owned_by_me], visible: :all)
            expect(page).to have_field("matrix.#{key}.criteria.owned_by_nobody", checked: value[:criteria][:owned_by_nobody], visible: :all)
            expect(page).to have_field("matrix.#{key}.criteria.subscribed", checked: value[:criteria][:subscribed], visible: :all)
            expect(page).to have_field("matrix.#{key}.criteria.no", checked: value[:criteria][:no], visible: :all)
            expect(page).to have_field("matrix.#{key}.channel", checked: value[:channel][:email], visible: :all)
          end

          find('.js-ticketDefaultNotificationsReset').click

          in_modal do
            click_on 'Yes'
          end

          await_empty_ajax_queue

          reseted_agent_notifications = Setting.find_by(name: 'ticket_agent_default_notifications').state_initial[:value]

          reseted_agent_notifications.each do |key, value|
            expect(page).to have_field("matrix.#{key}.criteria.owned_by_me", checked: value[:criteria][:owned_by_me], visible: :all)
            expect(page).to have_field("matrix.#{key}.criteria.owned_by_nobody", checked: value[:criteria][:owned_by_nobody], visible: :all)
            expect(page).to have_field("matrix.#{key}.criteria.subscribed", checked: value[:criteria][:subscribed], visible: :all)
            expect(page).to have_field("matrix.#{key}.criteria.no", checked: value[:criteria][:no], visible: :all)
            expect(page).to have_field("matrix.#{key}.channel", checked: value[:channel][:email], visible: :all)
          end
        end
      end
    end
  end

  describe 'apply default agent notifications to all agents', performs_jobs: true do
    it 'schedules the background job which then closes modal' do
      within(:active_content) do
        click(:href, '#notification')

        click '.js-ticketDefaultNotificationsApplyToAll'
      end

      in_modal disappears: false do
        find('[name="sure"]').fill_in with: 'CONFIRM'
        click_on 'Yes'
      end

      perform_enqueued_jobs only: ResetNotificationsPreferencesJob

      expect(page).to have_no_css('.modal')
    end
  end
end
