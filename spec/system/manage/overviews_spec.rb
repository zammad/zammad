# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Overviews', type: :system do
  let(:group) { create(:group) }

  let(:owner_one) { create(:agent, groups: [group]) }
  let(:owner_two)   { create(:agent, groups: [group]) }
  let(:owner_three) { create(:agent, groups: [group]) }

  let(:customer_one) { create(:customer, organization_id: organization_one.id, groups: [group]) }
  let(:customer_two)   { create(:customer, organization_id: organization_two.id, groups: [group]) }
  let(:customer_three) { create(:customer, organization_id: organization_three.id, groups: [group]) }

  let(:organization_one) { create(:organization, name: 'Test Org One') }
  let(:organization_two)   { create(:organization, name: 'Test Org Two') }
  let(:organization_three) { create(:organization, name: 'Test Org Three') }

  let!(:ticket_one) do
    create(:ticket,
           title:       'Test Ticket One',
           group:       group,
           owner_id:    owner_one.id,
           customer_id: customer_one.id)
  end

  let!(:ticket_two) do
    create(:ticket,
           title:       'Test Ticket Two',
           group:       group,
           owner_id:    owner_two.id,
           customer_id: customer_two.id)
  end

  let!(:ticket_three) do
    create(:ticket,
           title:       'Test Ticket Three',
           group:       group,
           owner_id:    owner_three.id,
           customer_id: customer_three.id)
  end

  let(:overview) { create(:overview, condition: condition) }

  context 'when ajax pagination' do
    include_examples 'pagination', model: :overview, klass: Overview, path: 'manage/overviews'
  end

  shared_examples 'previewing the correct ticket for single selected object' do
    before do
      wait.until { page.has_css?('.js-previewLoader.hide', visible: :all) }
      scroll_into_view('.ticket_selector')
    end

    context "with 'is' operator" do
      let(:operator) { 'is' }

      it 'shows selected customer ticket' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_css('tr.item', text: ticket_one.title)
        end
      end

      it 'does not show customer ticket that is not selected' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_no_selector('tr.item', text: ticket_two.title)
          expect(page).to have_no_selector('tr.item', text: ticket_three.title)
        end
      end
    end

    context "with 'is not' operator" do
      let(:operator) { 'is not' }

      it 'does not show selected customer ticket' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_no_selector('tr.item', text: ticket_one.title)
        end
      end

      it 'does not show customer ticket that is not selected' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_css('tr.item', text: ticket_two.title)
          expect(page).to have_css('tr.item', text: ticket_three.title)
        end
      end
    end
  end

  shared_examples 'previewing the correct ticket for multiple selected objects' do
    before do
      wait.until { page.has_css?('.js-previewLoader.hide', visible: :all) }
      scroll_into_view('.ticket_selector')
    end

    context "with 'is' operator" do
      let(:operator) { 'is' }

      it 'shows selected customer ticket' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_css('tr.item', text: ticket_one.title)
          expect(page).to have_css('tr.item', text: ticket_two.title)
        end
      end

      it 'does not show customer ticket that is not selected' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_no_selector('tr.item', text: ticket_three.title)
        end
      end
    end

    context "with 'is not' operator" do
      let(:operator) { 'is not' }

      it 'does not show selected customer ticket' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_no_selector('tr.item', text: ticket_one.title)
          expect(page).to have_no_selector('tr.item', text: ticket_two.title)
        end
      end

      it 'does not show customer ticket that is not selected' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_css('tr.item', text: ticket_three.title)
        end
      end
    end
  end

  context 'conditions for shown tickets' do
    context 'for customer' do
      context 'for new overview' do
        before do
          visit '/#manage/overviews'
          click_on 'New Overview'

          modal_ready

          within '.ticket_selector' do
            ticket_select = find('.js-attributeSelector select .js-ticket')
            ticket_select.select 'Customer'
            select operator, from: 'condition::ticket.customer_id::operator'
            select 'specific', from: 'condition::ticket.customer_id::pre_condition'
          end
        end

        context 'when single customer is selected' do
          before do
            within '.ticket_selector' do
              fill_in 'condition::ticket.customer_id::value_completion',	with: customer_one.firstname

              find("[data-object-id='#{customer_one.id}'].js-object").click
            end
          end

          it_behaves_like 'previewing the correct ticket for single selected object'
        end

        context 'when multiple customer is selected' do
          before do
            within '.ticket_selector' do
              fill_in 'condition::ticket.customer_id::value_completion',	with: customer_one.firstname
              find("[data-object-id='#{customer_one.id}'].js-object").click

              fill_in 'condition::ticket.customer_id::value_completion',	with: customer_two.firstname
              find("[data-object-id='#{customer_two.id}'].js-object").click
            end
          end

          it_behaves_like 'previewing the correct ticket for multiple selected objects'
        end
      end

      context 'for existing overview' do
        let(:condition) do
          { 'ticket.customer_id' => {
            operator:      operator,
            pre_condition: 'specific',
            value:         condition_value
          } }
        end

        before do
          overview

          visit '/#manage/overviews'

          within '.table-overview .js-tableBody' do
            find("tr[data-id='#{overview.id}']   td.table-draggable").click
          end
        end

        context 'when single customer exists' do
          let(:condition_value) { customer_one.id }

          it_behaves_like 'previewing the correct ticket for single selected object'
        end

        context 'when multiple customer exists' do
          let(:condition_value) { [customer_one.id, customer_two.id] }

          it_behaves_like 'previewing the correct ticket for multiple selected objects'
        end
      end
    end

    context 'for owner' do
      context 'for new overview' do
        before do
          visit '/#manage/overviews'
          click_on 'New Overview'

          modal_ready

          within '.ticket_selector' do
            ticket_select = find('.js-attributeSelector select .js-ticket')
            ticket_select.select 'Owner'
            select operator, from: 'condition::ticket.owner_id::operator'
            select 'specific', from: 'condition::ticket.owner_id::pre_condition'
          end
        end

        context 'when single owner is selected' do
          before do
            within '.ticket_selector' do
              fill_in 'condition::ticket.owner_id::value_completion',	with: owner_one.firstname

              find("[data-object-id='#{owner_one.id}'].js-object").click
            end
          end

          it_behaves_like 'previewing the correct ticket for single selected object'
        end

        context 'when multiple owner is selected' do
          before do
            within '.ticket_selector' do
              fill_in 'condition::ticket.owner_id::value_completion',	with: owner_one.firstname
              find("[data-object-id='#{owner_one.id}'].js-object").click

              fill_in 'condition::ticket.owner_id::value_completion',	with: owner_two.firstname
              find("[data-object-id='#{owner_two.id}'].js-object").click
            end
          end

          it_behaves_like 'previewing the correct ticket for multiple selected objects'
        end
      end

      context 'for existing overview' do
        let(:condition) do
          { 'ticket.owner_id' => {
            operator:      operator,
            pre_condition: 'specific',
            value:         condition_value
          } }
        end

        before do
          overview

          visit '/#manage/overviews'

          within '.table-overview .js-tableBody' do
            find("tr[data-id='#{overview.id}']   td.table-draggable").click
          end
        end

        context 'when single owner exists' do
          let(:condition_value) { owner_one.id }

          it_behaves_like 'previewing the correct ticket for single selected object'
        end

        context 'when multiple owner exists' do
          let(:condition_value) { [owner_one.id, owner_two.id] }

          it_behaves_like 'previewing the correct ticket for multiple selected objects'
        end
      end
    end

    context 'for organization' do
      context 'for new overview' do
        before do
          visit '/#manage/overviews'
          click_on 'New Overview'

          modal_ready

          within '.ticket_selector' do
            ticket_select = find('.js-attributeSelector select .js-ticket')
            ticket_select.select 'Organization'
            select operator, from: 'condition::ticket.organization_id::operator'
            select 'specific', from: 'condition::ticket.organization_id::pre_condition'
          end
        end

        context 'when single organization is selected' do
          before do
            within '.ticket_selector' do
              fill_in 'condition::ticket.organization_id::value_completion',	with: organization_one.name

              find('.js-optionsList span', text: organization_one.name).click
            end
          end

          it_behaves_like 'previewing the correct ticket for single selected object'
        end

        context 'when multiple organization is selected' do
          before do
            within '.ticket_selector' do
              fill_in 'condition::ticket.organization_id::value_completion',	with: organization_one.name
              find('.js-optionsList span', text: organization_one.name).click

              fill_in 'condition::ticket.organization_id::value_completion',	with: organization_two.name
              find('.js-optionsList span', text: organization_two.name).click
            end
          end

          it_behaves_like 'previewing the correct ticket for multiple selected objects'
        end
      end

      context 'for existing overview' do
        let(:condition) do
          { 'ticket.organization_id' => {
            operator:      operator,
            pre_condition: 'specific',
            value:         condition_value
          } }
        end

        before do
          overview

          visit '/#manage/overviews'

          within '.table-overview .js-tableBody' do
            find("tr[data-id='#{overview.id}']   td.table-draggable").click
          end
        end

        context 'when single organization exists' do
          let(:condition_value) { organization_one.id }

          it_behaves_like 'previewing the correct ticket for single selected object'
        end

        context 'when multiple organization exists' do
          let(:condition_value) { [organization_one.id, organization_two.id] }

          it_behaves_like 'previewing the correct ticket for multiple selected objects'
        end
      end
    end
  end

  # https://github.com/zammad/zammad/issues/4140
  context 'checking form validation' do
    shared_examples 'showing the error message if roles are empty' do
      it 'shows an error message if roles are empty' do
        in_modal disappears: false do
          wait.until do
            page.has_css?('.has-error')
            find('.has-error').has_content?('is required')
          end
        end
      end
    end

    context 'when new overview is created' do
      before do
        visit '/#manage/overviews'
        click_on 'New Overview'

        in_modal disappears: false do
          fill_in 'name', with: 'dummy'
          click_on 'Submit'
        end
      end

      include_examples 'showing the error message if roles are empty'
    end

    context 'when existing overview is edited' do
      let(:overview) { create(:overview, role_ids: [role_id]) }
      let(:role_id)  { Role.find_by(name: 'Agent').id }

      before do
        overview

        visit '/#manage/overviews'

        within '.table-overview .js-tableBody' do
          find("tr[data-id='#{overview.id}']   td.table-draggable").click
        end

        in_modal disappears: false do
          # delete the role and wait for the help message to appear
          find("div[data-attribute-name='role_ids'] div.js-selected div[data-value='#{role_id}']").click

          find("div[data-attribute-name='role_ids'] div.u-placeholder").has_content?('Nothing selected')

          click_on 'Submit'
        end
      end

      include_examples 'showing the error message if roles are empty'
    end
  end

  describe 'Overviews: On deletion of the 51th element it will show no entries #5696', authenticated_as: :authenticate, searchindex: true do
    def authenticate
      Overview.destroy_all
      create_list(:overview, 51)
      searchindex_model_reload([Overview])

      true
    end

    it 'redirects to the previous page' do
      visit '/#manage/overviews'

      first('.table-overview a', text: '2').click

      expect(page).to have_current_path(%r{/#manage/overviews/2/}, url: true)
      expect(page).to have_css('.table-overview tbody tr.item', count: 1)

      # Delete the single item on the second page
      find('.table-overview tbody .js-action').click
      find('[data-table-action="delete"]').click

      find('.modal-dialog .js-submit').click

      expect(page).to have_current_path(%r{/#manage/overviews/1/}, url: true)
      expect(page).to have_css('.table-overview tbody tr.item', count: 50)
    end
  end
end
