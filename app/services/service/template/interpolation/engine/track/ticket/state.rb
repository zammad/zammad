# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Template::Interpolation::Engine::Track::Ticket::State < Service::Template::Interpolation::Engine::Track
  def self.klass
    'Ticket::State'
  end
end
