# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Template::Interpolation::Engine::Track::Ticket::Article < Service::Template::Interpolation::Engine::Track

  def self.root?
    true
  end

  def self.klass
    'Ticket::Article'
  end

  def self.functions
    super + %w[
      created_by
      updated_by
      type
      sender
      origin_by
    ].freeze
  end

  def self.replacements
    user_functions = Service::Template::Interpolation::Engine::Track::User.functions
    {
      article:              functions,
      'article.sender':     Service::Template::Interpolation::Engine::Track::Ticket::Article::Sender.functions,
      'article.type':       Service::Template::Interpolation::Engine::Track::Ticket::Article::Type.functions,
      'article.created_by': user_functions,
      'article.updated_by': user_functions,
    }
  end
end
