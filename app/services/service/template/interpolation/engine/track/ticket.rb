# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Template::Interpolation::Engine::Track::Ticket < Service::Template::Interpolation::Engine::Track
  def self.root?
    true
  end

  def self.klass
    'Ticket'
  end

  def self.functions
    klass.constantize.attribute_names + %w[
      created_by
      current_state_color
      customer
      group
      organization
      owner
      priority
      state
      updated_by
    ].freeze
  end

  def self.replacements
    user_functions = Service::Template::Interpolation::Engine::Track::User.functions
    {
      ticket:                functions,
      'ticket.priority':     Service::Template::Interpolation::Engine::Track::Ticket::Priority.functions,
      'ticket.state':        Service::Template::Interpolation::Engine::Track::Ticket::State.functions,
      'ticket.group':        Service::Template::Interpolation::Engine::Track::Group.functions,
      'ticket.owner':        user_functions,
      'ticket.customer':     user_functions,
      'ticket.updated_by':   user_functions,
      'ticket.created_by':   user_functions,
      'ticket.organization': Service::Template::Interpolation::Engine::Track::Organization.functions,
    }
  end
end
