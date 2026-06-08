# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base

  def initialize(object, name, attribute)

    initialize_data_option(attribute)
    init_callback(attribute)

    add(object, name, attribute)
  end

  private

  def init_callback(_attribute); end

  def add(object, name, attribute)
    ObjectManager::Attribute.add(attribute_config(object, name, attribute))
    ObjectManager::Attribute.migration_execute(false)
  rescue
    # rubocop:disable Style/SpecialGlobalVars
    raise $!, "Problem with ObjectManager Attribute '#{name}': #{$!}", $!.backtrace
    # rubocop:enable Style/SpecialGlobalVars
  end

  def attribute_config(object, name, attribute)
    {
      object:        object.to_s,
      name:          name,
      display:       attribute.title,
      data_type:     data_type(attribute),
      data_option:   @data_option,
      editable:      !attribute.removable,
      active:        attribute.active,
      screens:       screens(object, attribute),
      position:      position(attribute),
      created_by_id: 1,
      updated_by_id: 1,
    }
  end

  def screens(object, attribute)
    return ticket_screens(attribute) if object.to_s == 'Ticket'

    {
      create: { '-all-' => { shown: true } },
      edit:   { '-all-' => { shown: true } },
      view:   { '-all-' => { shown: true } },
    }
  end

  def ticket_screens(attribute)
    customer = {
      shown:    attribute.visible_in_portal,
      required: attribute.required_in_portal,
    }
    agent = {
      shown:    true,
      required: attribute.required,
    }

    {
      create_middle: { 'ticket.customer' => customer, 'ticket.agent' => agent },
      edit:          { 'ticket.customer' => customer, 'ticket.agent' => agent },
    }
  end

  def initialize_data_option(attribute)
    @data_option = {
      null: !attribute.required,
      note: attribute.description,
    }
  end

  def position(attribute)
    attribute.position
  end

  def data_type(attribute)
    attribute.type
  end
end
