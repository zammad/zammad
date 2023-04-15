# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Expert conditions in Manage > Overviews', type: :system do
  let(:described_class) { Overview }
  let(:path)            { '/#manage/overviews' }

  context 'with expert conditions turned on' do
    before do
      Setting.set('ticket_allow_expert_conditions', true)
    end

    context 'with new objects' do
      before do
        visit path
        click '.content.active a[data-type="new"]'

        modal_ready
      end

      it 'renders default selector with expert mode turned off by default' do
        scroll_into_view('.ticket_selector')

        within '.ticket_selector' do
          check_condition(1, 'State', 'is')
          check_expert_mode(false)
        end
      end

      it 'renders default subclause and state condition' do
        scroll_into_view('.ticket_selector')

        within '.ticket_selector' do
          toggle_expert_mode(true)
          check_subclause_selector(1, 'Match all (AND)')
          check_condition(2, 'State', 'is')
        end
      end

      it 'supports toggling expert mode with seamless selector migration and downgrade' do
        scroll_into_view('.ticket_selector')

        within '.ticket_selector' do
          set_condition(1, 'State', 'is', value: %w[new])
          toggle_expert_mode(true)

          check_subclause_selector(1, 'Match all (AND)')
          check_condition(2, 'State', 'is', value: %w[new])

          set_condition(2, 'State', 'is', value: %w[new open])
          toggle_expert_mode(false)

          check_condition(1, 'State', 'is', value: %w[new open])
        end
      end

      it 'supports complex conditions with subclauses' do
        object_name = Faker::Name.unique.name
        fill_in 'Name', with: object_name

        # Select target roles, if the field is present, since this field is required.
        if has_css?('div[data-attribute-name="role_ids"]')
          find('div[data-attribute-name="role_ids"] div.js-pool div[data-value="1"]').click
        end

        scroll_into_view('.ticket_selector')

        within '.ticket_selector' do
          toggle_expert_mode(true)
          set_condition(2, 'State', 'is', value: %w[new open])
          insert_subclause_after(1, 'Match any (OR)')
          insert_condition_after(2, 'Priority', 'is not', value: ['2 normal', '3 high'])
        end

        click '.js-submit'
        await_empty_ajax_queue

        param_condition = {
          'operator'   => 'AND',
          'conditions' => [
            {
              'operator'   => 'OR',
              'conditions' => [
                {
                  'name'     => 'ticket.priority_id',
                  'operator' => 'is not',
                  'value'    => %w[2 3],
                },
              ],
            },
            {
              'name'     => 'ticket.state_id',
              'operator' => 'is',
              'value'    => %w[1 2],
            },
          ],
        }

        expect(described_class.find_by(name: object_name).condition).to eq(param_condition)
      end

      it 'saves condition with ticket tags attribute without errors (#4507)' do
        object_name = Faker::Name.unique.name
        fill_in 'Name', with: object_name

        # Select target roles, if the field is present, since this field is required.
        if has_css?('div[data-attribute-name="role_ids"]')
          find('div[data-attribute-name="role_ids"] div.js-pool div[data-value="1"]').click
        end

        scroll_into_view('.ticket_selector')

        within '.ticket_selector' do
          toggle_expert_mode(true)

          set_condition(2, 'Tags', 'contains all', value_token_input: %w[tag1 tag2])
        end

        click '.js-submit'
        await_empty_ajax_queue

        param_condition = {
          'operator'   => 'AND',
          'conditions' => [
            {
              'name'     => 'ticket.tags',
              'operator' => 'contains all',
              'value'    => %w[tag1 tag2].join(', '),
            },
          ],
        }

        expect(described_class.find_by(name: object_name).condition).to eq(param_condition)
      end

      context 'with drag and drop support' do
        it 'supports moving complete subclauses around' do
          scroll_into_view('.ticket_selector')

          within '.ticket_selector' do
            toggle_expert_mode(true)
            set_condition(2, 'State', 'is', value: %w[new])
            insert_subclause_after(2, 'Match any (OR)')
            insert_condition_after(3, 'Priority', 'is not', value: ['3 high'])

            subclause_draggable = find('.js-filterElement:nth-child(3) .draggable')
            state_condition = find('.js-filterElement:nth-child(2)')
            subclause_draggable.drag_to state_condition

            await_empty_ajax_queue

            check_subclause_selector(2, 'Match any (OR)')
            check_condition(3, 'Priority', 'is not', value: ['3 high'])
            check_condition(4, 'State', 'is', value: %w[new])

            param_condition = {
              'operator'   => 'AND',
              'conditions' => [
                {
                  'operator'   => 'OR',
                  'conditions' => [
                    {
                      'name'     => 'ticket.priority_id',
                      'operator' => 'is not',
                      'value'    => ['3'],
                    },
                  ],
                },
                {
                  'name'     => 'ticket.state_id',
                  'operator' => 'is',
                  'value'    => ['1'],
                },
              ],
            }

            check_expert_conditions(param_condition)
          end
        end

        it 'supports keeping nested levels' do
          scroll_into_view('.ticket_selector')

          within '.ticket_selector' do
            toggle_expert_mode(true)
            set_condition(2, 'State', 'is', value: %w[new])
            insert_subclause_after(1, 'Match any (OR)')
            insert_condition_after(2, 'Priority', 'is not', value: ['3 high'])

            state_condition_draggable = find('.js-filterElement:nth-child(4) .draggable')
            priority_condition = find('.js-filterElement:nth-child(3)')
            priority_height = priority_condition.native.size.height.to_i

            # Drag the state condition right above the priority, but drop it to the same subclause.
            #   Move the cursor vertically for the whole height of the priority element.
            #   Also, slightly move the cursor to the right, but more than the width of a single level constant (27px).
            #   Finally, drop the condition in order to assign it to the second level.
            page.driver.browser.action
              .move_to(state_condition_draggable.native)
              .click_and_hold
              .move_by(30, -priority_height)
              .release
              .perform

            await_empty_ajax_queue

            check_subclause_selector(2, 'Match any (OR)')
            check_condition(3, 'State', 'is', value: %w[new])
            check_condition(4, 'Priority', 'is not', value: ['3 high'])

            param_condition = {
              'operator'   => 'AND',
              'conditions' => [
                {
                  'operator'   => 'OR',
                  'conditions' => [
                    {
                      'name'     => 'ticket.state_id',
                      'operator' => 'is',
                      'value'    => ['1'],
                    },
                    {
                      'name'     => 'ticket.priority_id',
                      'operator' => 'is not',
                      'value'    => ['3'],
                    },
                  ],
                },
              ],
            }

            check_expert_conditions(param_condition)
          end
        end

        it 'supports changing nested levels' do
          scroll_into_view('.ticket_selector')

          within '.ticket_selector' do
            toggle_expert_mode(true)
            set_condition(2, 'State', 'is', value: %w[new])
            insert_subclause_after(1, 'Match any (OR)')
            insert_condition_after(2, 'Priority', 'is not', value: ['3 high'])

            state_condition_draggable = find('.js-filterElement:nth-child(4) .draggable')
            priority_condition = find('.js-filterElement:nth-child(3)')
            priority_height = priority_condition.native.size.height.to_i

            # Drag the state condition above the priority, but drop it on the same level as the subclause to break it.
            #   Move the cursor vertically for the whole height of the priority element.
            #   Also, do not move the cursor horizontally, so it stays flush with the element above.
            #   Finally, drop the condition in order to assign it to the first level.
            page.driver.browser.action
              .move_to(state_condition_draggable.native)
              .click_and_hold
              .move_by(0, -priority_height)
              .release
              .perform

            await_empty_ajax_queue

            check_subclause_selector(2, 'Match any (OR)')
            check_condition(3, 'State', 'is', value: %w[new])
            check_condition(4, 'Priority', 'is not', value: ['3 high'])

            param_condition = {
              'operator'   => 'AND',
              'conditions' => [
                {
                  'operator'   => 'OR',
                  'conditions' => [],
                },
                {
                  'name'     => 'ticket.state_id',
                  'operator' => 'is',
                  'value'    => ['1'],
                },
                {
                  'name'     => 'ticket.priority_id',
                  'operator' => 'is not',
                  'value'    => ['3'],
                },
              ],
            }

            check_expert_conditions(param_condition)
          end
        end
      end

      it 'does not allow duplicate attributes when the expert mode is switched off (#4414)' do
        scroll_into_view('.ticket_selector')

        within '.ticket_selector' do
          check_expert_mode(false)

          # Check if the State attribute is disabled in the new dropdown.
          find('.js-filterElement:nth-child(1) .js-add').click
          attribute_selector = find('.js-filterElement:nth-child(2) .js-attributeSelector select')
          expect(attribute_selector.find('option', text: 'State').disabled?).to be(true)
        end
      end
    end

    context 'with existing objects' do
      let(:object_name) { described_class.name.downcase }
      let(:object) { create(object_name.to_sym, condition: condition) }

      before do
        visit path

        within ".table-#{object_name} .js-tableBody" do
          find("tr[data-id='#{object.id}'] td.table-draggable").click
        end

        modal_ready
      end

      context 'with expert conditions' do
        let(:condition) do
          {
            'operator'   => 'OR',
            'conditions' => [
              {
                'name'     => 'ticket.state_id',
                'operator' => 'is',
                'value'    => %w[1],
              },
              {
                'operator'   => 'NOT',
                'conditions' => [
                  {
                    'name'     => 'ticket.priority_id',
                    'operator' => 'is',
                    'value'    => %w[1],
                  },
                ],
              },
            ],
          }
        end

        it 'renders in expert mode' do
          scroll_into_view('.ticket_selector')

          within '.ticket_selector' do
            check_expert_mode(true)
            check_subclause_selector(1, 'Match any (OR)')
            check_condition(2, 'State', 'is', value: ['new'])
            check_subclause_selector(3, 'Match none (NOT)')
            check_condition(4, 'Priority', 'is', value: ['1 low'])
          end
        end

        it 'shows a confirmation dialog when turning off the expert mode' do
          scroll_into_view('.ticket_selector')

          within '.ticket_selector' do
            toggle_expert_mode(false)
          end

          # We cannot use `in_modal` here, since the alert is shown in an additional, smaller dialog.
          within '.modal.modal--small' do # rubocop:disable Zammad/EnforceInModal
            expect(find('.modal-dialog')).to have_text('Are you sure?')
          end
        end

        it 'downgrades the selector with some data loss' do
          scroll_into_view('.ticket_selector')

          within '.ticket_selector' do
            toggle_expert_mode(false)
          end

          # We cannot use `in_modal` here, since the alert is shown in an additional, smaller dialog.
          within '.modal.modal--small' do # rubocop:disable Zammad/EnforceInModal
            click '.js-submit'
          end

          within '.ticket_selector' do
            check_expert_mode(false)
            check_condition(1, 'State', 'is', value: ['new'])
          end

          click '.js-submit'
          await_empty_ajax_queue

          param_condition = {
            'ticket.state_id' => {
              'operator' => 'is',
              'value'    => %w[1],
            },
          }

          expect(object.reload.condition).to eq(param_condition)
        end

        context 'when using ticket tags' do
          let(:condition) do
            {
              'operator'   => 'OR',
              'conditions' => [
                {
                  'name'     => 'ticket.tags',
                  'operator' => 'contains one',
                  'value'    => %w[tag1 tag2].join(', '),
                },
                {
                  'name'     => 'ticket.tags',
                  'operator' => 'contains one not',
                  'value'    => %w[tag3 tag4].join(', '),
                },
              ],
            }
          end

          it 'edits condition with ticket tags attribute without errors (#4507)' do
            scroll_into_view('.ticket_selector')

            within '.ticket_selector' do
              check_expert_mode(true)
              check_subclause_selector(1, 'Match any (OR)')
              check_condition(2, 'Tags', 'contains one', value_token_input: %w[tag1 tag2])
              check_condition(3, 'Tags', 'contains one not', value_token_input: %w[tag3 tag4])

              set_condition(2, 'Tags', 'contains all', value_token_input: %w[tag5 tag6])
              set_condition(3, 'Tags', 'contains all not', value_token_input: %w[tag7])
            end

            click '.js-submit'
            await_empty_ajax_queue

            param_condition = {
              'operator'   => 'OR',
              'conditions' => [
                {
                  'name'     => 'ticket.tags',
                  'operator' => 'contains all',
                  'value'    => %w[tag5 tag6].join(', '),
                },
                {
                  'name'     => 'ticket.tags',
                  'operator' => 'contains all not',
                  'value'    => %w[tag7].join(', '),
                },
              ],
            }

            expect(object.reload.condition).to eq(param_condition)
          end
        end

        context 'with pre-conditions' do
          let(:condition) do
            {
              'operator'   => 'OR',
              'conditions' => [
                {
                  'name'          => 'ticket.organization_id',
                  'operator'      => 'is',
                  'pre_condition' => 'current_user.organization_id',
                  'value'         => [],
                },
                {
                  'name'          => 'ticket.owner_id',
                  'operator'      => 'is',
                  'pre_condition' => 'not_set',
                  'value'         => [],
                },
              ],
            }
          end

          it 'saves changes made to pre-condition options (#4532)' do
            scroll_into_view('.ticket_selector')

            within '.ticket_selector' do
              check_expert_mode(true)
              check_subclause_selector(1, 'Match any (OR)')
              check_condition(2, 'Organization', 'is', pre_condition: 'current user organization')
              check_condition(3, 'Owner', 'is', pre_condition: 'not set (not defined)')

              set_condition(3, nil, nil, pre_condition: 'current user')
            end

            click '.js-submit'
            await_empty_ajax_queue

            param_condition = {
              'operator'   => 'OR',
              'conditions' => [
                {
                  'name'          => 'ticket.organization_id',
                  'operator'      => 'is',
                  'pre_condition' => 'current_user.organization_id',
                  'value'         => [],
                },
                {
                  'name'          => 'ticket.owner_id',
                  'operator'      => 'is',
                  'pre_condition' => 'current_user.id',
                  'value'         => [],
                },
              ],
            }

            expect(object.reload.condition).to eq(param_condition)

            within ".table-#{object_name} .js-tableBody" do
              find("tr[data-id='#{object.id}'] td.table-draggable").click
            end

            modal_ready
            scroll_into_view('.ticket_selector')

            within '.ticket_selector' do
              check_condition(3, 'Owner', 'is', pre_condition: 'current user')

              set_condition(2, nil, nil, pre_condition: 'not set (not defined)')
            end

            click '.js-submit'
            await_empty_ajax_queue

            param_condition = {
              'operator'   => 'OR',
              'conditions' => [
                {
                  'name'          => 'ticket.organization_id',
                  'operator'      => 'is',
                  'pre_condition' => 'not_set',
                  'value'         => [],
                },
                {
                  'name'          => 'ticket.owner_id',
                  'operator'      => 'is',
                  'pre_condition' => 'current_user.id',
                  'value'         => [],
                },
              ],
            }

            expect(object.reload.condition).to eq(param_condition)
          end
        end
      end

      context 'without expert conditions' do
        let(:condition) do
          {
            'ticket.state_id'    => {
              'operator' => 'is',
              'value'    => %w[1],
            },
            'ticket.priority_id' => {
              'operator' => 'is not',
              'value'    => %w[1],
            },
          }
        end

        it 'renders with the expert mode turned off' do
          scroll_into_view('.ticket_selector')

          within '.ticket_selector' do
            check_expert_mode(false)
            check_condition(1, 'State', 'is', value: ['new'])
            check_condition(2, 'Priority', 'is not', value: ['1 low'])
          end
        end

        it 'supports toggling expert mode with seamless selector migration and downgrade' do
          scroll_into_view('.ticket_selector')

          within '.ticket_selector' do
            toggle_expert_mode(true)

            check_subclause_selector(1, 'Match all (AND)')
            check_condition(2, 'State', 'is', value: ['new'])
            check_condition(3, 'Priority', 'is not', value: ['1 low'])

            toggle_expert_mode(false)

            check_condition(1, 'State', 'is', value: ['new'])
            check_condition(2, 'Priority', 'is not', value: ['1 low'])

            toggle_expert_mode(true)
          end

          click '.js-submit'
          await_empty_ajax_queue

          param_condition = {
            'operator'   => 'AND',
            'conditions' => [
              {
                'name'     => 'ticket.state_id',
                'operator' => 'is',
                'value'    => %w[1],
              },
              {
                'name'     => 'ticket.priority_id',
                'operator' => 'is not',
                'value'    => %w[1],
              },
            ],
          }

          expect(object.reload.condition).to eq(param_condition)
        end
      end
    end
  end

  context 'with expert conditions turned off' do
    before do
      Setting.set('ticket_allow_expert_conditions', false)
    end

    context 'with new objects' do
      before do
        visit path
        click '.content.active a[data-type="new"]'

        modal_ready
      end

      it 'renders default selector without expert mode switch' do
        scroll_into_view('.ticket_selector')

        within '.ticket_selector' do
          check_condition(1, 'State', 'is')
          expect(self).to have_no_selector('.js-switch')
        end
      end
    end

    context 'with existing objects' do
      let(:object_name) { described_class.name.downcase }
      let(:object) { create(object_name.to_sym, condition: condition) }

      before do
        visit path

        within ".table-#{object_name} .js-tableBody" do
          find("tr[data-id='#{object.id}'] td.table-draggable").click
        end

        modal_ready
      end

      context 'with expert conditions' do
        let(:condition) do
          {
            'operator'   => 'AND',
            'conditions' => [
              {
                'name'     => 'ticket.title',
                'operator' => 'contains',
                'value'    => 'w',
              },
              {
                'name'     => 'ticket.title',
                'operator' => 'contains',
                'value'    => 'e',
              },
              {
                'name'     => 'ticket.title',
                'operator' => 'contains',
                'value'    => 'l',
              },
            ],
          }
        end

        it 'shows an alert that a data loss may occur upon save' do
          within '.ticket_selector' do
            check_condition(1, 'Title', 'contains', value_input: 'l')
            expect(self).to have_selector('.js-alert')
          end
        end
      end

      context 'without expert conditions' do
        let(:condition) do
          {
            'operator'   => 'AND',
            'conditions' => [
              {
                'name'     => 'ticket.title',
                'operator' => 'contains',
                'value'    => 'welcome',
              },
            ],
          }
        end

        it 'does not show an alert' do
          within '.ticket_selector' do
            check_condition(1, 'Title', 'contains', value_input: 'welcome')
            expect(self).to have_no_selector('.js-alert')
          end
        end
      end
    end
  end

  def check_subclause_selector(row_number, value)
    subclause_selector = find(".js-filterElement:nth-child(#{row_number}) .js-subclauseSelector select")
    selected_option = subclause_selector.find("option[value='#{subclause_selector.value}']")
    expect(selected_option).to have_text(value)
  end

  def set_subclause_selector(row_number, value)
    subclause_selector = find(".js-filterElement:nth-child(#{row_number}) .js-subclauseSelector select")
    option = subclause_selector.find('option', text: value)
    option.select_option
  end

  def check_attribute_selector(row_number, value)
    attribute_selector = find(".js-filterElement:nth-child(#{row_number}) .js-attributeSelector select")
    selected_option = attribute_selector.find("option[value='#{attribute_selector.value}']")
    expect(selected_option).to have_text(value)
  end

  def set_attribute_selector(row_number, value)
    attribute_selector = find(".js-filterElement:nth-child(#{row_number}) .js-attributeSelector select")
    option = attribute_selector.find('option', text: value)
    option.select_option
  end

  def check_operator_selector(row_number, value)
    operator_selector = find(".js-filterElement:nth-child(#{row_number}) .js-operator select")
    selected_option = operator_selector.find("option[value='#{operator_selector.value}']")
    expect(selected_option).to have_text(value)
  end

  def set_operator_selector(row_number, value)
    operator_selector = find(".js-filterElement:nth-child(#{row_number}) .js-operator select")
    option = operator_selector.find("option[value='#{value}']")
    option.select_option
  end

  def check_pre_condition_selector(row_number, value)
    precondition_selector = find(".js-filterElement:nth-child(#{row_number}) .js-preCondition select")
    selected_option = precondition_selector.find("option[value='#{precondition_selector.value}']")
    expect(selected_option).to have_text(value)
  end

  def set_precondition_selector(row_number, value)
    precondition_selector = find(".js-filterElement:nth-child(#{row_number}) .js-preCondition select")
    option = precondition_selector.find('option', text: value)
    option.select_option
  end

  def check_customer_fullname(row_number, customer_fullname)
    token_label = find(".js-filterElement:nth-child(#{row_number}) .js-value .token-label")
    expect(token_label).to have_text(customer_fullname)
  end

  def check_value_input(row_number, value)
    input = find(".js-filterElement:nth-child(#{row_number}) .js-value input")
    expect(input.value).to eq(value)
  end

  def check_value_token_input(row_number, value)
    input = find(".js-filterElement:nth-child(#{row_number}) .js-value input.form-control", visible: :all)
    expect(input.value).to eq(value.join(', '))
  end

  def check_value_selector(row_number, value)
    value_selector = find(".js-filterElement:nth-child(#{row_number}) .js-value select")
    value_selector.value.each_with_index do |v, index|
      selected_option = value_selector.find("option[value='#{v}']")
      expect(selected_option).to have_text(value[index])
    end
  end

  def set_value_input(row_number, value)
    value_input = find(".js-filterElement:nth-child(#{row_number}) .js-value input")
    value_input.fill_in with: value.join
  end

  def set_value_token_input(row_number, value)
    value_token_input = find(".js-filterElement:nth-child(#{row_number}) .js-value .token-input")
    value_token_input.fill_in with: value.join(', ')
    send_keys :tab
  end

  def set_value_selector(row_number, value)
    value_selector = find(".js-filterElement:nth-child(#{row_number}) .js-value select")
    value.each do |v|
      option = value_selector.find('option', text: v)
      option.select_option
    end
  end

  def check_condition(row_number, attribute, operator, pre_condition: nil, value: nil, value_input: nil, value_token_input: nil, customer_fullname: nil)
    check_attribute_selector(row_number, attribute)
    check_operator_selector(row_number, operator)

    if !pre_condition.nil?
      check_pre_condition_selector(row_number, pre_condition)
    end

    if !customer_fullname.nil?
      check_customer_fullname(row_number, customer_fullname)
    end

    if !value_input.nil?
      check_value_input(row_number, value_input)
    elsif !value_token_input.nil?
      check_value_token_input(row_number, value_token_input)
    end

    return if value.nil?

    check_value_selector(row_number, value)
  end

  def set_condition(row_number, attribute, operator, pre_condition: nil, value: nil, value_input: nil, value_token_input: nil)
    set_attribute_selector(row_number, attribute) if attribute.present?
    set_operator_selector(row_number, operator) if operator.present?

    if !pre_condition.nil?
      set_precondition_selector(row_number, pre_condition)
    end

    if !value_input.nil?
      set_value_input(row_number, value_input)
    elsif !value_token_input.nil?
      set_value_token_input(row_number, value_token_input)
    end

    return if value.nil?

    set_value_selector(row_number, value)
  end

  def check_expert_conditions(param_condition)
    param_value = JSON.parse(find('.js-expertConditions input', visible: :all).value)
    expect(param_value).to eq(param_condition)
  end

  def toggle_expert_mode(value)
    switch = find('.js-switch')

    if switch.find('input', visible: :all).checked?
      switch.click if !value
    elsif value
      switch.click
    end
  end

  def check_expert_mode(value)
    checkbox = find('.js-switch input', visible: :all)

    if value
      expect(checkbox).to be_checked
    else
      expect(checkbox).not_to be_checked
    end
  end

  def insert_subclause_after(row_number, value)
    find(".js-filterElement:nth-child(#{row_number}) .js-subclause").click
    set_subclause_selector(row_number + 1, value)
  end

  def insert_condition_after(row_number, attribute, operator, pre_condition: nil, value: nil)
    find(".js-filterElement:nth-child(#{row_number}) .js-add").click
    set_condition(row_number + 1, attribute, operator, pre_condition: pre_condition, value: value)
  end
end
