# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module FieldActions # rubocop:disable Metrics/ModuleLength

  delegate :app_host, to: Capybara

  # Check the field value of a form input field.
  #
  # @example
  #  check_input_field_value('input_field_name', 'text', visible: :all)
  #
  def check_input_field_value(name, value, **find_options)
    input_field = find("input[name='#{name}']", **find_options)
    expect(input_field.value).to eq(value)
  end

  # Set the field value of a form input field.
  #
  # @example
  #  set_input_field_value('input_field_name', 'text', visible: :all)
  #
  def set_input_field_value(name, value, **find_options)
    # input_field = find("input[name='#{name}']", **find_options)
    # expect(input_field.value).to eq(value)
    find("input[name='#{name}']", **find_options).fill_in with: value
  end

  # Set the field value of a form tree_select field.
  #
  # @example
  #  set_tree_select_value('tree_select', 'Users')                       # via label
  #  set_tree_select_value('tree_select', 1)                             # via value
  #  set_tree_select_value('tree_select', 'Group 1 › Group 2 › Group 3') # via full path
  #
  def set_tree_select_value(name, value)
    tree_select_field = page.find(%( input[name='#{name}']+.js-input )) # search input
      .click                                                            # focus
      .ancestor('.controls', order: :reverse, match: :first)            # find container

    # Try to find the option via its value.
    if tree_select_field.has_css?("[data-value='#{value}']", wait: false)
      tree_select_field.find("[data-value='#{value}']")
        .click
      return
    end

    # Try to find the option via its label.
    if tree_select_field.has_css?("[data-display-name='#{value}']", wait: false)
      tree_select_field.find("[data-display-name='#{value}']")
        .click
      return
    end

    path_delimiter = ' › '
    raise Capybara::ElementNotFound if !value.match(path_delimiter)

    components   = value.split(path_delimiter)
    current_path = []

    # Try to drill down to a nested label.
    components.each_with_index do |component, index|
      current_path.push(component)
      display_name = current_path.join(path_delimiter)

      # Handle last item.
      if index == components.length - 1
        tree_select_field.find("[role='menu']:not(.velocity-animating) [data-display-name='#{display_name}']")
        .click

      # Handle parent items.
      else
        tree_select_field.find("[role='menu']:not(.velocity-animating) [data-display-name='#{display_name}'] .searchableSelect-option-arrow")
          .click
      end
    end
  end

  # Set the field value of a form external data source field.
  #
  # @example
  #  set_external_data_source_value('external_data_source', '*', 'Users')
  #
  def set_external_data_source_value(name, search, value)
    input_elem = page.find(%( input[name*='#{name}']+.js-input ))

    input_elem.fill_in with: search, fill_options: { clear: :backspace }

    find('.js-optionsList span', text: value).click
  end

  # Check the field value of a form select field.
  #
  # @example
  #  check_select_field_value('select_field_name', '1')
  #
  def check_select_field_value(name, value)
    select_field = find("select[name='#{name}']")
    expect(select_field.value).to eq(value)
  end

  # Set the field value of a form select field.
  #
  # @example
  #  set_select_field_value('select_field_name', '1')
  #
  def set_select_field_value(name, value)
    find("select[name='#{name}'] option[value='#{value}']").select_option
  end

  # Set the value of a form select field via an option label.
  #
  # @example
  #  set_select_field_label('select_field_name', 'A')
  #
  def set_select_field_label(name, label)
    find("select[name='#{name}']").select(label)
  end

  # Check the field value of a form tree select field.
  #
  # @example
  #  check_tree_select_field_value('select_field_name', '1')
  #
  def check_tree_select_field_value(name, value)
    check_input_field_value(name, value, visible: :all)
  end

  # Check the field value of a form editor field.
  #
  # @example
  #  check_editor_field_value('editor_field_name', 'plain text')
  #
  def check_editor_field_value(name, value)
    editor_field = find("[data-name='#{name}']")
    expect(editor_field.text).to have_text(value)
  end

  # Set the field value of a form editor field.
  #
  # @example
  #  set_editor_field_value('editor_field_name', 'plain text')
  #
  def set_editor_field_value(name, value)
    find("[data-name='#{name}']").set(value)

    # Explicitly trigger the input event to mark the form field as "dirty".
    execute_script("$('[data-name=\"#{name}\"]').trigger('input')")
  end

  # Check the field value of a form date field.
  #
  # @example
  #  check_date_field_value('date_field_name', '20/12/2020')
  #
  def check_date_field_value(name, value)
    date_attribute_field = find("div[data-name='#{name}'] input[data-item='date']")
    expect(date_attribute_field.value).to eq(value)
  end

  # Set the field value of a form date field.
  #
  # @example
  #  set_date_field_value('date_field_name', '20/12/2020')
  #
  def set_date_field_value(name, value)
    # We need a special handling for a blank value, to trigger a correct update.
    if value.blank?
      find("div[data-name='#{name}'] input[data-item='date']").send_keys :backspace
    end

    find("div[data-name='#{name}'] .js-datepicker").fill_in with: value
  end

  # Check the field value of a form time field.
  #
  # @example
  #  check_time_field_value('date_field_name', '08:00')
  #
  def check_time_field_value(name, value)
    date_attribute_field = find("div[data-name='#{name}'] input[data-item='time']")
    expect(date_attribute_field.value).to eq(value)
  end

  # Set the field value of a form time field.
  #
  # @example
  #  set_time_field_value('date_field_name', '08:00')
  #
  def set_time_field_value(name, value)
    # We need a special handling for a blank value, to trigger a correct update.
    if value.blank?
      find("div[data-name='#{name}'] input[data-item='time']").send_keys :backspace
    end

    find("div[data-name='#{name}'] .js-timepicker").fill_in with: value
  end

  # Check the field value of a form tokens field.
  #
  # @example
  #  check_tokens_field_value('tags', 'tag name')
  #  check_tokens_field_value('tags', %w[tag1 tag2 tag3)
  #
  def check_tokens_field_value(name, value, **find_options)
    input_value = if value.is_a?(Array)
                    value.join(', ')
                  else
                    value
                  end

    expect(find("input[name='#{name}']", visible: :all, **find_options).value).to eq(input_value)
  end

  # Set the field value of a form tokens field.
  #
  # @example
  #  set_tokens_field_value('tags', 'tag name')
  #  set_tokens_field_value('tags', %w[tag1 tag2 tag3])
  #
  def set_tokens_field_value(name, value, **find_options)
    input_string = if value.is_a?(Array)
                     value.join(', ')
                   else
                     value
                   end

    find("input[name='#{name}'] ~ input.token-input", **find_options).send_keys input_string, :tab

    token_count = if value.is_a?(Array)
                    value.length
                  else
                    1
                  end

    wait.until { find_all("input[name='#{name}'] ~ .token").length == token_count }
  end

  # Check the field value of a form switch field.
  #
  # @example
  #  check_switch_field_value('switch_field_name', true)
  #
  def check_switch_field_value(name, value, **find_options)
    switch_field = find("input[name='#{name}']", visible: :all, **find_options)

    if value
      expect(switch_field).to be_checked
    else
      expect(switch_field).not_to be_checked
    end
  end

  # Set the field value of a form switch field.
  #
  # @example
  #  set_switch_field_value('switch_field_name', false)
  #
  def set_switch_field_value(name, value, **find_options)
    find("input[name='#{name}']", visible: :all, **find_options).set(value)
  end
end

RSpec.configure do |config|
  config.include FieldActions, type: :system
end
