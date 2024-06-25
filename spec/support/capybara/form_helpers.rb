# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require_relative 'test_flags'

# Form helpers below are loaded for the new stack app only and provide functions for returning the form field elements.
module FormHelpers
  @form_context = nil

  # Returns the outer container element of the form field via its label.
  #   The returned object is always an instance of `Capybara::Node::Element``, with some added sugar on top.
  def find_outer(label, **find_options)
    ZammadFormFieldCapybaraElementDelegator.new(find('.formkit-outer') { |element| element.has_css?('label', text: label, **find_options) }, @form_context)
  end

  # Usage:
  #
  #   find_input('Title')
  #   find_select('Owner')
  #   find_treeselect('Category')
  #   find_autocomplete('Customer')
  #   find_editor('Text')
  #   find_datepicker('Pending till')
  #   find_toggle('Remember me')
  #
  #   # In case of ambiguous labels, make sure to pass `exact_text` option
  #   find_datepicker(nil, exact_text: 'Date')
  #
  alias find_input find_outer
  alias find_select find_outer
  alias find_treeselect find_outer
  alias find_autocomplete find_outer
  alias find_editor find_outer
  alias find_datepicker find_outer
  alias find_toggle find_outer

  # Returns the outer container element of the form field radio via its ID.
  #   The returned object is always an instance of `Capybara::Node::Element``, with some added sugar on top.
  def find_radio(name, **find_options)
    ZammadFormFieldCapybaraElementDelegator.new(first("[name^=\"#{name}\"]", **find_options).ancestor('.formkit-outer'), @form_context)
  end

  # Provides a form context for stabilizing multiple field interactions.
  #   This is implemented by tracking of the expected form updater and other GraphQL responses.
  #   To define custom starting form updater response number, use the `form_updater_gql_number` argument (default: nil).
  #
  # Usage:
  #
  #   within_form(form_updater_gql_number: 2) do
  #     find_autocomplete('CC').search_for_options([email_address_1, email_address_2])
  #     find_autocomplete('Tags').search_for_options([tag_1, tag_2, tag_3]).select_options(%w[foo bar])
  #     find_editor('Text').type(body)
  #   end
  #
  def within_form(form_updater_gql_number: nil)
    setup_form_context(form_updater_gql_number)
    yield
    demolish_form_context
  end

  private

  def setup_form_context(form_updater_gql_number)
    @form_context = ZammadFormContext.new

    return if form_updater_gql_number.blank?

    @form_context.init_form_updater(form_updater_gql_number)
  end

  def demolish_form_context
    @form_context = nil
  end
end

# Extension below allows for execution of custom actions on the returned form field elements.
#   This class delegates any missing methods upstream to `Capybara::Node::Element` class.
class ZammadFormFieldCapybaraElementDelegator < SimpleDelegator
  attr_reader :element, :form_context

  include Capybara::DSL
  include BrowserTestHelper
  include TestFlags

  def initialize(element, form_context)
    @element = element
    @form_context = form_context

    super(element)
  end

  # Returns identifier of the form field.
  def field_id
    return element.find('.formkit-input', visible: :all)['id'] if input? || type_date? || type_datetime?
    return element.find('textarea')['id'] if type_textarea?
    return element.find('.formkit-fieldset')['id'] if type_radio?
    return element.find('[role="textbox"]')['id'] if type_editor?
    return element.find('[role="switch"], input[type="checkbox"]', visible: :all)['id'] if type_toggle? || type_checkbox?

    element.find('output', visible: :all)['id']
  end

  # Returns (hidden) input element used by several form field implementations to track the current value.
  #   NOTE: A returned element might not be a regular INPUT field due to custom implementation.
  def input_element
    element.find("##{field_id}", visible: :all)
  end

  # Searches treeselect and autocomplete fields for supplied option via its label and selects it.
  #
  # Usage:
  #
  #   find_treeselect('Tree Select').search_for_option('Parent 1::Option A')
  #   find_autocomplete('Tags').search_for_option(tag_1)
  #
  #   # To wait for a custom GraphQL response, you can provide expected `gql_filename` and/or `gql_number`.
  #   find_autocomplete('Custom').search_for_option('foo', gql_filename: 'shared/entities/user/graphql/queries/user.graphql', gql_number: 4)
  #
  #   # To select an autocomplete option with a different text than the query, provide an optional `label` parameter.
  #   find autocomplete('Customer').search_for_option(customer.email, label: customer.fullname)
  #
  def search_for_option(query, label: query, gql_filename: '', gql_number: 1, **find_options)
    return search_for_options(query, gql_filename: gql_filename, gql_number: gql_number, **find_options) if query.is_a?(Array)
    return search_for_tags_option(query, gql_filename: gql_filename, gql_number: gql_number) if type_tags?
    return search_for_autocomplete_option(query, label: label, gql_filename: gql_filename, gql_number: gql_number, **find_options) if autocomplete?

    raise 'Field does not support searching for options' if !type_treeselect?

    element.click

    wait_for_test_flag("field-tree-select-#{field_id}.opened")

    # calculate before closing, since we cannot access it, if dialog is closed
    is_multi_select = multi_select?

    browse_for_option(query, **find_options) do |option|
      find('[role="searchbox"]').fill_in with: option
      find('[role="option"]', text: option, **find_options).click

      maybe_wait_for_form_updater
    end

    send_keys(:escape) if is_multi_select

    wait_for_test_flag("field-tree-select-#{field_id}.closed")

    self # support chaining
  end

  # Searches treeselect and autocomplete fields for supplied options via their labels and selects them.
  #   NOTE: The field must support multiple selection, otherwise an error will be raised.
  #
  # Usage:
  #
  #   find_treeselect('Tree Select').search_for_options(['Parent 1::Option A', 'Parent 2::Option B', 'Option C'])
  #   find_autocomplete('Tags').search_for_options([tag_1, tag_2, tag_3])
  #
  #   # To wait for a custom GraphQL response, you can provide expected `gql_filename` and/or `gql_number`.
  #   find_autocomplete('Tags').search_for_option('foo', gql_number: 3)
  #
  def search_for_options(queries, labels: queries, gql_filename: '', gql_number: 1, **find_options)
    return search_for_tags_options(queries, gql_filename: gql_filename, gql_number: gql_number) if type_tags?
    return search_for_autocomplete_options(queries, labels: labels, gql_filename: gql_filename, gql_number: gql_number, **find_options) if autocomplete?

    raise 'Field does not support searching for options' if !type_treeselect?

    element.click

    wait_for_test_flag("field-tree-select-#{field_id}.opened")

    raise 'Field does not support multiple selection' if !multi_select?

    queries.each do |query|
      browse_for_option(query, **find_options) do |option, rewind|
        find('[role="searchbox"]').fill_in with: option
        find('[role="option"]', text: option, **find_options).click

        maybe_wait_for_form_updater

        rewind.call
      end
    end

    send_keys(:escape)

    wait_for_test_flag("field-tree-select-#{field_id}.closed")

    self # support chaining
  end

  # Selects an option in select, treeselect nad autocomplete fields via its label.
  #   NOTE: The option must be part of initial options provided by the field, no autocomplete search will occur.
  #
  # Usage:
  #
  #   find_select('Owner').select_option('Test Admin Agent')
  #   find_treeselect('Tree Select').select_option('Parent 1::Option A')
  #   find_autocomplete('Organization').select_option(secondary_organizations.last.name)
  #
  def select_option(label, **find_options)
    return select_options(label, **find_options) if label.is_a?(Array)
    return select_treeselect_option(label, **find_options) if type_treeselect?
    return select_tags_option(label, **find_options) if type_tags?
    return select_autocomplete_option(label, **find_options) if autocomplete?

    raise 'Element is not a field of type select' if !type_select?

    element.click

    wait_for_test_flag('common-select.opened')

    # calculate before closing, since we cannot access it, if dialog is closed
    is_multi_select = multi_select?

    select_option_by_label(label, **find_options)

    send_keys(:escape) if is_multi_select

    wait_for_test_flag('common-select.closed')

    self # support chaining
  end

  # Selects multiple options in select, treeselect and autocomplete fields via its label.
  #   NOTE: The option must be part of initial options provided by the field, no autocomplete search will occur.
  #   NOTE: The field must support multiple selection, otherwise an error will be raised.
  #
  # Usage:
  #
  #   find_select('Multi Select').select_options(['Option 1', 'Option 2'])
  #   find_treeselect('Multi Tree Select').select_options(['Parent 1::Option A', 'Parent 2::Option C'])
  #   find_autocomplete('Tags').select_options(%w[foo bar])
  #
  def select_options(labels, **find_options)
    return select_treeselect_options(labels, **find_options) if type_treeselect?
    return select_tags_options(labels, **find_options) if type_tags?
    return select_autocomplete_options(labels, **find_options) if autocomplete?

    raise 'Element is not a field of type select' if !type_select?

    element.click

    wait_for_test_flag('common-select.opened')

    raise 'Field does not support multiple selection' if !multi_select?

    labels.each do |label|
      select_option_by_label(label, **find_options)
    end

    send_keys(:escape)

    wait_for_test_flag('common-select.closed')

    self # support chaining
  end

  # Clears selection in select, treeselect and autocomplete fields.
  #   NOTE: The field must support selection clearing, otherwise an error will be raised.
  def clear_selection
    raise 'Field does not support clearing selection' if !type_select? && !type_treeselect? && !autocomplete?

    element.find('[role="button"][aria-label="Clear Selection"]').click

    maybe_wait_for_form_updater

    self # support chaining
  end

  # Types the provided text into an input or editor field.
  #
  # Usage:
  #
  #   find_input('Title').type(body)
  #   find_editor('Text').type(body)
  #
  def type(text, **type_options)
    return type_editor(text, **type_options) if type_editor?

    input_element.fill_in with: text

    maybe_wait_for_form_updater

    self # support chaining
  end

  def type_editor(text, click: true)
    raise 'Field does not support typing' if !type_editor?

    cursor_home_shortcut = mac_platform? ? %i[command up] : %i[control home]
    input_element.click.send_keys(cursor_home_shortcut) if click
    input_element.send_keys(text)

    maybe_wait_for_form_updater

    self # support chaining
  end

  # Clears the input of text, editor, date and datetime fields.
  def clear
    return clear_date if type_date? || type_datetime?

    raise 'Field does not support clearing' if !input? && !type_editor?

    input_element.click.send_keys([magic_key, 'a'], :backspace)

    maybe_wait_for_form_updater

    self # support chaining
  end

  # Selects a date in a date picker field.
  #
  # Usage:
  #   find_datepicker('Date Picker').select_date(Date.today)
  #   find_datepicker('Date Picker').select_date('2023-01-01')
  #
  def select_date(date)
    raise 'Field does not support selecting dates' if !type_date? && !type_datetime?

    element.click

    wait_for_test_flag("field-date-time-#{field_id}.opened")

    date = Date.parse(date) if !date.is_a?(Date) && !date.is_a?(DateTime) && !date.is_a?(Time)

    element.find('[aria-label="Open the years overlay"]').click
    element.find('.dp__overlay_col', text: date.year).click
    element.find('[aria-label="Open the months overlay"]').click
    element.find('.dp__overlay_col', text: date.strftime('%b')).click

    id = date.strftime('%Y-%m-%d')
    element.find_by_id(id).click # rubocop:disable Rails/DynamicFindBy

    yield if block_given?

    # close_date_picker(element)

    # wait_for_test_flag("field-date-time-#{field_id}.closed")

    maybe_wait_for_form_updater

    self # support chaining
  end

  # Selects a date and enters time in a datetime picker field.
  #
  # Usage:
  #   find_datepicker('Date Time').select_datetime(DateTime.now)
  #   find_datepicker('Date Time').select_datetime('2023-01-01T09:00:00.000Z')
  #
  def select_datetime(datetime)
    raise 'Field does not support selecting datetimes' if !type_datetime?

    datetime = DateTime.parse(datetime) if !datetime.is_a?(DateTime) && !datetime.is_a?(Time)

    select_date(datetime) do
      element.find('[aria-label="Open the time picker"]').click

      element.find('[aria-label="Open the hours overlay"]').click
      element.find('.dp__overlay_col', text: format('%02d', datetime.hour)).click

      element.find('[aria-label="Open the minutes overlay"]').click
      element.find('.dp__overlay_col', text: format('%02d', datetime.min)).click

      meridian_indicator = element.find('[aria-label="Toggle AM/PM mode"]')
      meridian_indicator.click if meridian_indicator.text != datetime.strftime('%p')
    end
  end

  # Types date into a date field.
  #
  # Usage:
  #   find_datepicker('Date Picker').type_date(Date.today)
  #   find_datepicker('Date Picker').type_date('2023-01-01')
  #
  def type_date(date)
    raise 'Field does not support typing dates' if !type_date?

    date = Date.parse(date) if !date.is_a?(Date)

    # TODO: Support locales other than `en`, depending on the language of the current user.
    input_element.fill_in with: date.strftime('%m/%d/%Y')
    input_element.send_keys :return

    # wait_for_test_flag("field-date-time-#{field_id}.opened")

    # close_date_picker(element)

    # wait_for_test_flag("field-date-time-#{field_id}.closed")

    maybe_wait_for_form_updater

    self # support chaining
  end

  # Types date and time into a date field.
  #
  # Usage:
  #   find_datepicker('Date Time').type_datetime(DateTime.now)
  #   find_datepicker('Date Picker').type_datetime('2023-01-01T09:00:00.000Z')
  #
  def type_datetime(datetime)
    raise 'Field does not support typing datetimes' if !type_datetime?

    datetime = DateTime.parse(datetime) if !datetime.is_a?(DateTime) && !datetime.is_a?(Time)

    # TODO: Support locales other than `en`, depending on the language of the current user.
    input_element.fill_in with: datetime.strftime('%m/%d/%Y %-l:%M %P')
    input_element.send_keys :return

    # wait_for_test_flag("field-date-time-#{field_id}.opened")

    # close_date_picker(element)

    # wait_for_test_flag("field-date-time-#{field_id}.closed")

    maybe_wait_for_form_updater

    self # support chaining
  end

  # Selects a choice in a radio form field.
  #
  # Usage:
  #
  #   find_radio('articleSenderType').select_option('Outbound Call')
  #
  def select_choice(choice, **find_options)
    raise 'Field does not support choice selection' if !type_radio?

    input_element.find('label', exact_text: choice, **find_options).click

    maybe_wait_for_form_updater

    self # support chaining
  end

  def toggle
    raise 'Field does not support toggling' if !type_toggle? && !type_checkbox?

    element.find('label').click

    self # support chaining
  end

  def toggle_on
    raise 'Field does not support toggling on' if !type_toggle? && !type_checkbox?

    element.find('label').click if input_element['aria-checked'] == 'false' || !input_element.checked?

    self # support chaining
  end

  def toggle_off
    raise 'Field does not support toggling off' if !type_toggle? && !type_checkbox?

    element.find('label').click if input_element['aria-checked'] == 'true' || input_element.checked?

    self # support chaining
  end

  def open
    element.click
    wait_until_opened

    self # support chaining
  end

  def close
    send_keys(:escape)
    wait_until_closed

    self # support chaining
  end

  # Dialogs are teleported to the root element, so we must search them within the document body.
  #   In order to improve the test performance, we don't do any implicit waits here.
  #   Instead, we do explicit waits when opening/closing dialogs within the actions.
  def dialog_element
    if type_select?
      page.find('#common-select[role="dialog"]', wait: false)
    elsif type_treeselect?
      page.find("#dialog-field-tree-select-#{field_id}", wait: false)
    elsif type_tags?
      page.find("#dialog-field-tags-#{field_id}", wait: false)
    elsif autocomplete?
      page.find("#dialog-field-auto-complete-#{field_id}", wait: false)
    end
  end

  private

  def method_missing(method_name, *, &)

    # Simulate pseudo-methods in format of `#type_[name]?` in order to determine the internal type of the field.
    if method_name.to_s =~ %r{^type_(.+)\?$}
      return element['data-type'] == $1
    end

    super
  end

  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s =~ %r{^type_(.+)\?$} || super
  end

  def input?
    type_text? || type_color? || type_email? || type_number? || type_tel? || type_url? || type_password?
  end

  def autocomplete?
    type_autocomplete? || type_customer? || type_organization? || type_recipient? || type_externalDataSource?
  end

  # Input elements in supported fields define data attribute for "multiple" state.
  def multi_select?
    input_element['data-multiple'] == 'true'
  end

  def wait_until_opened
    return wait_for_test_flag('common-select.opened') if type_select?
    return wait_for_test_flag("field-tree-select-#{field_id}.opened") if type_treeselect?
    return wait_for_test_flag("field-date-time-#{field_id}.opened") if type_date? || !type_datetime
    return wait_for_test_flag("field-tags-#{field_id}.opened") if type_tags?
    return wait_for_test_flag("field-auto-complete-#{field_id}.opened") if autocomplete?

    raise 'Element cannot be opened'
  end

  def wait_until_closed
    return wait_for_test_flag('common-select.closed') if type_select?
    return wait_for_test_flag("field-tree-select-#{field_id}.closed") if type_treeselect?
    return wait_for_test_flag("field-date-time-#{field_id}.closed") if type_date? || !type_datetime
    return wait_for_test_flag("field-tags-#{field_id}.closed") if type_tags?
    return wait_for_test_flag("field-auto-complete-#{field_id}.closed") if autocomplete?

    raise 'Element cannot be closed'
  end

  def select_option_by_label(label, **find_options)
    within dialog_element do
      find('[role="option"]', text: label, **find_options).click

      maybe_wait_for_form_updater
    end
  end

  def browse_for_option(path, **find_options)
    components = path.split('::')

    # Goes back to the root page by clicking on back button multiple times.
    rewind = proc do
      depth = components.size - 1
      depth.times do
        find('[role="button"][aria-label="Back to previous page"]').click
      end
    end

    components.each_with_index do |option, index|

      # Child option is always the last item.
      if index == components.size - 1
        within dialog_element do
          yield option, rewind
        end

        next
      end

      # Parents come before.
      within dialog_element do
        find('[role="option"] span', text: option, **find_options).sibling('svg[role=link]').click
      end
    end
  end

  def search_for_tags_option(query, gql_filename: '', gql_number: 1)
    element.click

    wait_for_test_flag("field-tags-#{field_id}.opened")

    within dialog_element do
      find('[role="searchbox"]').fill_in with: query

      send_keys(:tab)

      wait_for_autocomplete_gql(gql_filename, gql_number)
    end

    send_keys(:escape)

    wait_for_test_flag("field-tags-#{field_id}.closed")

    maybe_wait_for_form_updater

    self # support chaining
  end

  def search_for_autocomplete_option(query, label: query, gql_filename: '', gql_number: 1, already_open: false, **find_options)
    if !already_open
      element.click

      wait_for_test_flag("field-auto-complete-#{field_id}.opened")
    end

    # calculate before closing, since we cannot access it, if dialog is closed
    is_multi_select = multi_select?

    within dialog_element do
      find('[role="searchbox"]').fill_in with: query

      wait_for_autocomplete_gql(gql_filename, gql_number)

      find('[role="option"]', text: label, **find_options).click

      maybe_wait_for_form_updater
    end

    send_keys(:escape) if is_multi_select

    wait_for_test_flag("field-auto-complete-#{field_id}.closed")

    self # support chaining
  end

  def search_for_tags_options(queries, gql_filename: '', gql_number: 1)
    element.click

    wait_for_test_flag("field-tags-#{field_id}.opened")

    raise 'Field does not support multiple selection' if !multi_select?

    within dialog_element do
      queries.each do |query|
        find('[role="searchbox"]').fill_in with: query

        send_keys(:tab)

        wait_for_autocomplete_gql(gql_filename, gql_number)
      end
    end

    send_keys(:escape)

    wait_for_test_flag("field-tags-#{field_id}.closed")

    maybe_wait_for_form_updater

    self # support chaining
  end

  def search_for_autocomplete_options(queries, labels: queries, gql_filename: '', gql_number: 1, **find_options)
    element.click

    wait_for_test_flag("field-auto-complete-#{field_id}.opened")

    within dialog_element do
      queries.each_with_index do |query, index|
        find('[role="searchbox"]').fill_in with: query

        wait_for_autocomplete_gql(gql_filename, gql_number + index)

        raise 'Field does not support multiple selection' if !multi_select?

        find('[role="option"]', text: labels[index], **find_options).click

        maybe_wait_for_form_updater

        find('[aria-label="Clear Search"]').click
      end
    end

    send_keys(:escape)

    wait_for_test_flag("field-auto-complete-#{field_id}.closed")

    self # support chaining
  end

  def select_treeselect_option(label, **find_options)
    element.click

    wait_for_test_flag("field-tree-select-#{field_id}.opened")

    # calculate before closing, since we cannot access it, if dialog is closed
    is_multi_select = multi_select?

    browse_for_option(label, **find_options) do |option|
      find('[role="option"]', text: option, **find_options).click

      maybe_wait_for_form_updater
    end

    send_keys(:escape) if is_multi_select

    wait_for_test_flag("field-tree-select-#{field_id}.closed")

    self # support chaining
  end

  def select_tags_option(label, **find_options)
    element.click

    wait_for_test_flag("field-tags-#{field_id}.opened")

    select_option_by_label(label, **find_options)

    send_keys(:escape)

    wait_for_test_flag("field-tags-#{field_id}.closed")

    self # support chaining
  end

  def select_autocomplete_option(label, **find_options)
    element.click

    wait_for_test_flag("field-auto-complete-#{field_id}.opened")

    # calculate before closing, since we cannot access it, if dialog is closed
    is_multi_select = multi_select?

    select_option_by_label(label, **find_options)

    send_keys(:escape) if is_multi_select

    wait_for_test_flag("field-auto-complete-#{field_id}.closed")

    self # support chaining
  end

  def select_treeselect_options(labels, **find_options)
    element.click

    wait_for_test_flag("field-tree-select-#{field_id}.opened")

    raise 'Field does not support multiple selection' if !multi_select?

    labels.each do |label|
      browse_for_option(label, **find_options) do |option, rewind|
        find('[role="option"]', text: option, **find_options).click

        maybe_wait_for_form_updater

        rewind.call
      end
    end

    send_keys(:escape)

    wait_for_test_flag("field-tree-select-#{field_id}.closed")

    self # support chaining
  end

  def select_tags_options(labels, **find_options)
    element.click

    wait_for_test_flag("field-tags-#{field_id}.opened")

    raise 'Field does not support multiple selection' if !multi_select?

    labels.each do |label|
      select_option_by_label(label, **find_options)
    end

    send_keys(:escape)

    wait_for_test_flag("field-tags-#{field_id}.closed")

    self # support chaining
  end

  def select_autocomplete_options(labels, **find_options)
    element.click

    wait_for_test_flag("field-auto-complete-#{field_id}.opened")

    raise 'Field does not support multiple selection' if !multi_select?

    labels.each do |label|
      select_option_by_label(label, **find_options)
    end

    send_keys(:escape)

    wait_for_test_flag("field-auto-complete-#{field_id}.closed")

    self # support chaining
  end

  # If a GraphQL filename is passed, we will explicitly wait for it here.
  #   Otherwise, we will implicitly wait for a query depending on the type of the field.
  #   If no waits are to be done, we display a friendly warning to devs, since this can lead to some instability.
  #   In form context, expected response number will be automatically increased and tracked.
  def wait_for_autocomplete_gql(gql_filename, gql_number)
    gql_number = autocomplete_gql_number(gql_filename) || gql_number

    if gql_filename.present?
      wait_for_gql(gql_filename, number: gql_number)
    elsif type_customer?
      wait_for_gql('shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/user.graphql', number: gql_number)
    elsif type_organization?
      wait_for_gql('shared/components/Form/fields/FieldOrganization/graphql/queries/autocompleteSearch/organization.graphql', number: gql_number)
    elsif type_recipient?
      wait_for_gql('shared/components/Form/fields/FieldRecipient/graphql/queries/autocompleteSearch/recipient.graphql', number: gql_number)
    elsif type_externalDataSource?
      wait_for_gql('shared/components/Form/fields/FieldExternalDataSource/graphql/queries/autocompleteSearchObjectAttributeExternalDataSource.graphql', number: gql_number)
    elsif type_tags?
      # NB: tags autocomplete query fires only once?!
      wait_for_gql('shared/entities/tags/graphql/queries/autocompleteTags.graphql', number: 1, skip_clearing: true)
    else
      warn 'Warning: missing `wait_for_gql` in `search_for_autocomplete_option()`, might lead to instability'
    end
  end

  def autocomplete_gql_number(gql_filename)
    return nil if form_context.nil?

    return form_context.form_gql_number(:autocomplete) if gql_filename.present?
    return form_context.form_gql_number(:customer) if type_customer?
    return form_context.form_gql_number(:organization) if type_organization?
    return form_context.form_gql_number(:recipient) if type_recipient?
    return form_context.form_gql_number(:externalDataSource) if type_externalDataSource?

    form_context.form_gql_number(:tags) if type_tags?
  end

  def triggers_form_updater?
    element['data-triggers-form-updater'] == 'true'
  end

  def maybe_wait_for_form_updater
    return if form_context.nil? || !triggers_form_updater?

    gql_number = form_context.form_gql_number(:form_updater)

    wait_for_form_updater(gql_number)
  end

  # Click on the upper left corner of the date picker field to close it.
  def close_date_picker(element)
    element_width = element.native.size.width.to_i
    element_height = element.native.size.height.to_i
    element.click(x: -element_width / 2, y: -element_height / 2)
  end

  def clear_date
    element.find('[role="button"][aria-label="Clear Selection"]').click

    maybe_wait_for_form_updater

    self # support chaining
  end
end

class ZammadFormContext
  attr_reader :context

  def initialize
    @context = {}
  end

  def init_form_updater(number)
    context[:gql_number] = {}
    context[:gql_number][:form_updater] = number
  end

  def form_gql_number(name)
    if context[:gql_number].nil?
      context[:gql_number] = {}
    end

    if context[:gql_number][name].nil?
      context[:gql_number][name] = 1
    else
      context[:gql_number][name] += 1
    end

    context[:gql_number][name]
  end
end

RSpec.configure do |config|
  config.include FormHelpers, type: :system, app: :mobile
  config.include FormHelpers, type: :system, app: :desktop_view
end
