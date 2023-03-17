# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Trigger', mariadb: true, type: :system do

  def open_new_trigger_dialog
    visit '/#manage/trigger'
    click_on 'New Trigger'
  end

  context 'Selector' do

    context 'custom attribute', db_strategy: :reset do

      it 'enables selection of multiple values for select attribute' do
        attribute = create_attribute :object_manager_attribute_select,
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
                                     }

        open_new_trigger_dialog

        in_modal do
          within '.ticket_selector' do
            find('.js-attributeSelector select').select(attribute.display)

            expect(find('.js-value select')).to be_multiple
          end
        end
      end

      it 'enables selection of multiple values for multiselect attribute' do
        attribute = create_attribute :object_manager_attribute_multiselect,
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
                                     }

        open_new_trigger_dialog

        in_modal do
          within '.ticket_selector' do
            find('.js-attributeSelector select').select(attribute.display)

            expect(find('.js-value select')).to be_multiple
          end
        end
      end
    end

    it 'sets a customer email address with no @ character' do
      visit '/#manage/trigger'

      click '.page-header-meta .btn--success'

      in_modal do
        find(".js-attributeSelector select option[value='customer.email']").select_option
        fill_in 'condition::customer.email::value', with: 'zammad.com'
        fill_in 'Name', with: 'trigger 1'
        click '.js-submit'
      end
    end
  end

  context 'Perform' do

    context 'Tags' do

      it 'shows tag selection list in foreground' do
        tag_item = create(:tag_item)

        open_new_trigger_dialog

        in_modal disappears: false do
          within '.ticket_perform_action' do
            find('.js-attributeSelector select').select('Tags')

            input = find('.js-value .token-input')
            input.fill_in with: tag_item.name.slice(0, 3)
          end
        end

        # widget is shown within modal, but placed outside of modal in DOM tree.
        expect(page).to have_css('.ui-autocomplete.ui-widget-content') { |elem| !elem.obscured? }
      end
    end
  end

  context 'ajax pagination' do
    include_examples 'pagination', model: :trigger, klass: Trigger, path: 'manage/trigger'
  end

  context "with elements which do not support 'has changed' operator" do
    it "check 'created_at' element" do
      open_new_trigger_dialog

      in_modal do
        within '.ticket_selector' do
          find(".js-attributeSelector select option[value='ticket.created_at']").select_option

          expect(page).to have_no_css('select[name="condition::ticket.created_at::operator"] option[value="has changed"]')
        end
      end
    end

    it "check 'updated_at' element" do
      open_new_trigger_dialog

      in_modal do
        within '.ticket_selector' do
          find(".js-attributeSelector select option[value='ticket.updated_at']").select_option

          expect(page).to have_no_css('select[name="condition::ticket.updated_at::operator"] option[value="has changed"]')
        end
      end
    end
  end

  context 'when ticket is updated with a multiselect trigger condition', authenticated_as: :owner, db_strategy: :reset do
    let(:options) do
      {
        a: 'a',
        b: 'b',
        c: 'c',
        d: 'd',
        e: 'e',
      }
    end

    let(:trigger_values) { %w[a b c] }

    let!(:attribute) do
      create_attribute :object_manager_attribute_multiselect, :required_screen,
                       data_option: {
                         options:    options,
                         default:    '',
                         null:       false,
                         relation:   '',
                         maxlength:  255,
                         nulloption: true,
                       },
                       name:        'multiselect'
    end

    let(:group) { create(:group) }
    let(:owner)   { create(:admin, group_ids: [group.id]) }
    let!(:ticket) { create(:ticket, group: group,) }

    before do
      visit '/#manage/trigger'
      click_on 'New Trigger'

      in_modal do
        fill_in 'Name',	with: 'Test Trigger'
        within '.ticket_selector' do
          find('.js-attributeSelector select').select attribute.display
          find('.js-operator select').select operator
          trigger_values.each { |value| find('.js-value select').select value }
        end

        within '.ticket_perform_action' do
          find('.js-attributeSelector select').select 'Note'

          within '.js-setArticle' do
            fill_in 'Subject', with: 'Test subject note'
            find('[data-name="perform::article.note::body"]').set 'Test body note'
          end
        end

        click_button
      end

      visit "#ticket/zoom/#{ticket.id}"

      ticket_multiselect_values.each do |value|
        within '.sidebar-content .multiselect select' do
          select value
        end
      end

      click_button 'Update'

    end

    shared_examples 'updating the ticket with the trigger condition' do
      it 'updates the ticket with the trigger condition' do
        wait.until { ticket.multiselect_previously_changed? && ticket.articles.present? }
        expect(ticket.articles).not_to be_empty
        expect(page).to have_text 'Test body note'
      end
    end

    context "with 'contains all' used" do
      let(:operator) { 'contains all' }

      context 'when updated value is the same with trigger value' do
        let(:ticket_multiselect_values) { trigger_values }

        it_behaves_like 'updating the ticket with the trigger condition'
      end

      context 'when all value is selected' do
        let(:ticket_multiselect_values) { options.values }

        it_behaves_like 'updating the ticket with the trigger condition'
      end
    end

    context "with 'contains one' used" do
      let(:operator) { 'contains one' }

      context 'when updated value is the same with trigger value' do
        let(:ticket_multiselect_values) { trigger_values }

        it_behaves_like 'updating the ticket with the trigger condition'
      end

      context 'when all value is selected' do
        let(:ticket_multiselect_values) { options.values }

        it_behaves_like 'updating the ticket with the trigger condition'
      end

      context 'when updated value contains only one of the trigger value' do
        let(:ticket_multiselect_values) { [trigger_values.first] }

        it_behaves_like 'updating the ticket with the trigger condition'
      end

      context 'when updated value does not contain one of the trigger value' do
        let(:ticket_multiselect_values) { options.values - [trigger_values.first] }

        it_behaves_like 'updating the ticket with the trigger condition'
      end
    end

    context "with 'contains all not' used" do
      let(:operator) { 'contains all not' }

      context 'when updated value is different from the trigger value' do
        let(:ticket_multiselect_values) { options.values - trigger_values }

        it_behaves_like 'updating the ticket with the trigger condition'
      end

      context 'when updated value contains only one of the trigger value' do
        let(:ticket_multiselect_values) { [trigger_values.first] }

        it_behaves_like 'updating the ticket with the trigger condition'
      end

      context 'when updated value does not contain one of the trigger value' do
        let(:ticket_multiselect_values) { options.values - [trigger_values.first] }

        it_behaves_like 'updating the ticket with the trigger condition'
      end
    end

    context "with 'contains one not' used" do
      let(:operator) { 'contains one not' }

      context 'when updated value is different from the trigger value' do
        let(:ticket_multiselect_values) { options.values - trigger_values }

        it_behaves_like 'updating the ticket with the trigger condition'
      end
    end
  end
end
