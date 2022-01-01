# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module FieldActions

  delegate :app_host, to: Capybara

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
end

RSpec.configure do |config|
  config.include FieldActions, type: :system
end
