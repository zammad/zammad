# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::EntryPoints
  class Mutations < Gql::Types::BaseObject
    description 'All available mutations.'

    # Load all available Gql::mutations so that they can be iterated.
    Dir.glob('**/*.rb', base: "#{__dir__}/../mutations/").each do |file|
      subclass = file.sub(%r{.rb$}, '').camelize
      next if subclass.starts_with? 'Base' # Ignore base classes.

      "Gql::Mutations::#{subclass}".constantize.register_in_schema(self)
    end
  end
end
