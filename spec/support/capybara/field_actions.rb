# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module FieldActions

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

  # Check the field value of a form select field.
  #
  # @example
  #  check_select_field_value('select_field_name', '1')
  #
  def check_select_field_value(name, value)
    select_field = find("select[name='#{name}']")
    expect(select_field.value).to eq(value)
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
end

RSpec.configure do |config|
  config.include FieldActions, type: :system
end
