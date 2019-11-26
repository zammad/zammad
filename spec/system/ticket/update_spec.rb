require 'rails_helper'

require 'system/examples/text_modules_examples'
require 'system/examples/macros_examples'

RSpec.describe 'Ticket Update', type: :system do

  let(:group) { Group.find_by(name: 'Users') }
  let(:ticket) { create(:ticket, group: group) }

  # Regression test for issue #2242 - mandatory fields can be empty (or "-") on ticket update
  context 'when updating a ticket without its required select attributes' do
    it 'frontend checks reject the update', db_strategy: :reset do
      # setup and migrate a required select attribute
      attribute = create_attribute(:object_manager_attribute_select,
                                   screens:     attributes_for(:required_screen),
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
        expect(page).to have_no_css('.js-submitDropdown .js-submit[disabled]', wait: 2)
      end

      # the update should have failed and thus the ticket is still in the new state
      expect(ticket.reload.state.name).to eq('new')

      within(:active_content) do
        # update should work now
        find(".edit [name=#{attribute.name}]").select('name 2')
        click('.js-attributeBar .js-submit')
        expect(page).to have_no_css('.js-submitDropdown .js-submit[disabled]', wait: 2)
      end

      ticket.reload
      expect(ticket[attribute.name]).to eq('name 2')
      expect(ticket.state.name).to eq('closed')
    end
  end

  context 'when updating a ticket with macro' do
    context 'when required tree_select field is present' do
      it 'performs no validation (#2492)', db_strategy: :reset do
        # setup and migrate a required select attribute
        attribute = create_attribute(:object_manager_attribute_tree_select,
                                     screens:     attributes_for(:required_screen),
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

          expect(page).to have_field(attribute.name, with: '', visible: false)
          expect(page).to have_select('state_id',
                                      selected: 'new',
                                      options:  ['new', 'closed', 'open', 'pending close', 'pending reminder'])

          click('.js-openDropdownMacro')
          click(".js-dropdownActionMacro[data-id=\"#{macro.id}\"]")
          expect(page).not_to have_css('.js-submitDropdown .js-submit[disabled]', wait: 2)
        end

        expect(page).to have_field(attribute.name, with: attribute_value, visible: false)
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
          expect(page).not_to have_css('.js-submitDropdown .js-submit[disabled]', wait: 2)
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
        expect(article.internal).to eq(true)
      end
    end
  end

  # Issue #2469 - Add information "Ticket merged" to History
  context 'when merging tickets' do
    it 'tickets history of both tickets should show the merge event' do
      user = create :user
      origin_ticket = create :ticket, group: group
      target_ticket = create :ticket, group: group
      origin_ticket.merge_to(ticket_id: target_ticket.id, user_id: user.id)

      visit "#ticket/zoom/#{origin_ticket.id}"
      within(:active_content) do
        expect(page).to have_css('.js-actions .dropdown-toggle', wait: 3)
        click '.js-actions .dropdown-toggle'
        click '.js-actions .dropdown-menu [data-type="ticket-history"]'

        expect(page).to have_css('.modal', wait: 3)
        modal = find('.modal')
        expect(modal).to have_content "This ticket was merged into ticket ##{target_ticket.number}"
        expect(modal).to have_link "##{target_ticket.number}", href: "#ticket/zoom/#{target_ticket.id}"

        visit "#ticket/zoom/#{target_ticket.id}"
        expect(page).to have_css('.js-actions .dropdown-toggle', wait: 3)
        click '.js-actions .dropdown-toggle'
        click '.js-actions .dropdown-menu [data-type="ticket-history"]'

        expect(page).to have_css('.modal', wait: 3)
        modal = find('.modal')
        expect(modal).to have_content("Ticket ##{origin_ticket.number} was merged into this ticket")
        expect(modal).to have_link "##{origin_ticket.number}", href: "#ticket/zoom/#{origin_ticket.id}"
      end
    end
  end

  context 'when using text modules' do
    include_examples 'text modules', path: "#ticket/zoom/#{Ticket.first.id}"
  end

  context 'when using macros' do
    include_examples 'macros', path: "#ticket/zoom/#{Ticket.first.id}"
  end
end
