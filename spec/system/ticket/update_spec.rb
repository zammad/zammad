# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'system/examples/text_modules_examples'
require 'system/examples/macros_examples'

RSpec.describe 'Ticket Update', type: :system do

  let(:group)  { Group.find_by(name: 'Users') }
  let(:ticket) { create(:ticket, group: group) }

  # Regression test for issue #2242 - mandatory fields can be empty (or "-") on ticket update
  context 'when updating a ticket without its required select attributes' do
    it 'frontend checks reject the update', db_strategy: :reset do
      # setup and migrate a required select attribute
      attribute = create_attribute(:object_manager_attribute_select, :required_screen,
                                   data_option: {
                                     options:    {
                                       'name 1': 'name 1',
                                       'name 2': 'name 2',
                                     },
                                     default:    '',
                                     null:       false,
                                     relation:   '',
                                     maxlength:  255,
                                     nulloption: true,
                                   })

      # create a new ticket and attempt to update its state without the required select attribute
      visit "#ticket/zoom/#{ticket.id}"
      within(:active_content) do
        expect(page).to have_selector('.js-objectNumber', text: ticket.number)

        select('closed', from: 'state_id')
        click('.js-attributeBar .js-submit')
        expect(page).to have_no_css('.js-submitDropdown .js-submit[disabled]')
      end

      # the update should have failed and thus the ticket is still in the new state
      expect(ticket.reload.state.name).to eq('new')

      within(:active_content) do
        # update should work now
        find(".edit [name=#{attribute.name}]").select('name 2')
        click('.js-attributeBar .js-submit')
        expect(page).to have_no_css('.js-submitDropdown .js-submit[disabled]')
      end

      ticket.reload
      expect(ticket[attribute.name]).to eq('name 2')
      expect(ticket.state.name).to eq('closed')
    end
  end

  context 'when updating a ticket date attribute', db_strategy: :reset do
    let!(:date_attribute) do
      create_attribute(
        :object_manager_attribute_date,
        name:        'example_date',
        screens:     {
          create: {
            'ticket.agent' => {
              shown: true
            },
          },
          edit:   {
            'ticket.agent' => {
              shown: true
            }
          },
          view:   {
            'ticket.agent' => {
              shown: true
            },
          }
        },
        data_option: {
          'future' => true,
          'past'   => false,
          'diff'   => 0,
          'null'   => true,
        }
      )
    end

    let(:ticket) { create(:ticket, group: group, "#{date_attribute.name}": '2018-02-28') }

    it 'set date attribute to empty' do
      visit "#ticket/zoom/#{ticket.id}"

      within(:active_content) do
        check_date_field_value(date_attribute.name, '02/28/2018')

        set_date_field_value(date_attribute.name, '')

        click('.js-attributeBar .js-submit')
        expect(page).to have_no_css('.js-submitDropdown .js-submit[disabled]')

        ticket.reload
        expect(ticket[date_attribute.name]).to be_nil
      end
    end
  end

  context 'when updating a ticket with macro' do
    context 'when required tree_select field is present' do
      it 'performs no validation (#2492)', db_strategy: :reset do
        # setup and migrate a required select attribute
        attribute = create_attribute(:object_manager_attribute_tree_select, :required_screen,
                                     data_option: {
                                       options:    [
                                         {
                                           name:  'name 1',
                                           value: 'name 1',
                                         },
                                         {
                                           name:  'name 2',
                                           value: 'name 2',
                                         },
                                       ],
                                       default:    '',
                                       null:       false,
                                       relation:   '',
                                       maxlength:  255,
                                       nulloption: true,
                                     })

        attribute_value = 'name 2'
        state           = Ticket::State.by_category(:closed).first
        macro           = create(:macro,
                                 perform:         {
                                   'ticket.state_id'          => {
                                     value: state.id,
                                   },
                                   "ticket.#{attribute.name}" => {
                                     value: attribute_value,
                                   },
                                 },
                                 ux_flow_next_up: 'none',)

        # refresh browser to get macro accessible
        refresh

        # create a new ticket and attempt to update its state without the required select attribute
        visit "#ticket/zoom/#{ticket.id}"

        within(:active_content) do
          expect(page).to have_selector('.js-objectNumber', text: ticket.number)

          expect(page).to have_field(attribute.name, with: '', visible: :hidden)
          expect(page).to have_select('state_id',
                                      selected: 'new',
                                      options:  ['new', 'closed', 'open', 'pending close', 'pending reminder'])

          click('.js-openDropdownMacro')
          click(".js-dropdownActionMacro[data-id=\"#{macro.id}\"]")
          expect(page).to have_no_css('.js-submitDropdown .js-submit[disabled]')
        end

        expect(page).to have_field(attribute.name, with: attribute_value, visible: :hidden)
        expect(page).to have_select('state_id',
                                    selected: 'closed',
                                    options:  ['closed', 'open', 'pending close', 'pending reminder'])

        # the update should not have failed and thus the ticket is in closed state
        ticket.reload
        expect(ticket[attribute.name]).to eq(attribute_value)
        expect(ticket.state.name).to eq(state.name)
      end
    end

    context 'when macro has article configured' do
      it 'creates an article with the configured attributes' do
        state = Ticket::State.find_by(name: 'closed')
        macro = create(:macro,
                       perform:         {
                         'ticket.state_id' => {
                           value: state.id,
                         },
                         'article.note'    => {
                           'body'     => 'test body',
                           'internal' => 'true',
                           'subject'  => 'test sub'
                         },
                       },
                       ux_flow_next_up: 'none',)

        # refresh browser to get macro accessible
        refresh

        # create a new ticket and attempt to update its state without the required select attribute
        visit "#ticket/zoom/#{ticket.id}"

        within(:active_content) do
          expect(page).to have_selector('.js-objectNumber', text: ticket.number)
          expect(page).to have_select('state_id',
                                      selected: 'new',
                                      options:  ['new', 'closed', 'open', 'pending close', 'pending reminder'])

          click('.js-openDropdownMacro')
          click(".js-dropdownActionMacro[data-id=\"#{macro.id}\"]")
          expect(page).to have_no_css('.js-submitDropdown .js-submit[disabled]')
        end

        expect(page).to have_selector('.content.active .article-content', text: 'test body')
        expect(page).to have_select('state_id',
                                    selected: 'closed',
                                    options:  ['closed', 'open', 'pending close', 'pending reminder'])

        # the update should not have failed and thus the ticket is in closed state
        ticket.reload
        expect(ticket.state.name).to eq(state.name)
        article = ticket.articles.last
        expect(article).to be_present
        expect(article.body).to eq('test body')
        expect(article.subject).to eq('test sub')
        expect(article.internal).to be(true)
      end
    end
  end

  context 'when merging tickets' do
    let!(:user)          { create(:user) }
    let!(:origin_ticket) { create(:ticket, group: group) }
    let!(:target_ticket) { create(:ticket, group: group) }

    before do
      origin_ticket.merge_to(ticket_id: target_ticket.id, user_id: user.id)
    end

    # Issue #2469 - Add information "Ticket merged" to History
    it 'tickets history of both tickets should show the merge event' do
      visit "#ticket/zoom/#{origin_ticket.id}"
      within(:active_content) do
        expect(page).to have_css('.js-actions .dropdown-toggle')
        click '.js-actions .dropdown-toggle'
        click '.js-actions .dropdown-menu [data-type="ticket-history"]'

        in_modal do
          expect(page).to have_content "this ticket was merged into ticket ##{target_ticket.number}"
          expect(page).to have_link "##{target_ticket.number}", href: "#ticket/zoom/#{target_ticket.id}"
        end

        visit "#ticket/zoom/#{target_ticket.id}"
        expect(page).to have_css('.js-actions .dropdown-toggle')
        click '.js-actions .dropdown-toggle'
        click '.js-actions .dropdown-menu [data-type="ticket-history"]'

        in_modal do
          expect(page).to have_content("ticket ##{origin_ticket.number} was merged into this ticket")
          expect(page).to have_link "##{origin_ticket.number}", href: "#ticket/zoom/#{origin_ticket.id}"
        end
      end
    end

    # Issue #2960 - Ticket removal of merged / linked tickets doesn't remove references
    context 'when the merged origin ticket is deleted' do
      before do
        origin_ticket.destroy
      end

      it 'shows the target ticket history' do
        visit "#ticket/zoom/#{target_ticket.id}"
        within(:active_content) do
          expect(page).to have_css('.js-actions .dropdown-toggle')
          click '.js-actions .dropdown-toggle'
          click '.js-actions .dropdown-menu [data-type="ticket-history"]'
        end

        in_modal do
          expect(page).to have_text "##{origin_ticket.number} #{origin_ticket.title}"
        end
      end
    end

    # Issue #2960 - Ticket removal of merged / linked tickets doesn't remove references
    context 'when the merged target ticket is deleted' do
      before do
        target_ticket.destroy
      end

      it 'shows the origin history' do
        visit "#ticket/zoom/#{origin_ticket.id}"
        within(:active_content) do
          expect(page).to have_css('.js-actions .dropdown-toggle')
          click '.js-actions .dropdown-toggle'
          click '.js-actions .dropdown-menu [data-type="ticket-history"]'
        end

        in_modal do
          expect(page).to have_text "##{target_ticket.number} #{target_ticket.title}"
        end
      end
    end
  end

  context 'when closing taskbar tab for ticket' do
    it 'close task bar entry after some changes in ticket update form' do
      visit "#ticket/zoom/#{ticket.id}"

      within(:active_content) do
        find('.js-textarea').send_keys('some note')
      end

      taskbar_tab_close("Ticket-#{ticket.id}")
    end
  end

  context 'when using text modules' do
    include_examples 'text modules', path: "#ticket/zoom/#{Ticket.first.id}"
  end

  context 'when using macros' do
    include_examples 'macros', path: "#ticket/zoom/#{Ticket.first.id}"
  end

  context 'when group will be changed' do
    let(:user) { User.find_by(email: 'agent1@example.com') }
    let(:ticket) { create(:ticket, group: group, owner: user) }

    it 'check that owner resets after group change' do
      visit "#ticket/zoom/#{ticket.id}"

      expect(page).to have_field('owner_id', with: user.id)

      find('[name=group_id]').select '-'

      expect(page).to have_field('owner_id', with: '')
    end
  end
end
