# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Client facing identifiers cannot contain a namespace separator: GraphQL enum
#   values allow no ':', and taskbar keys end up as DOM ids of the legacy stack.
#   Encoding it (instead of removing it) keeps the identifier unambiguous, no
#   matter whether it is a class name ('ProjectBaller::Project') or another
#   namespaced identifier ('Email::Account').
module IdentifierName
  NAMESPACE_SEPARATOR = '__'.freeze

  def self.encode(name)
    name.gsub('::', NAMESPACE_SEPARATOR)
  end
end
