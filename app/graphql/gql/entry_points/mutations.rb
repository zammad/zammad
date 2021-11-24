# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::EntryPoints
  class Mutations < Gql::Types::BaseObject
    description 'All available mutations.'

    # No auth required for the main mutation entry point, Gql::mutations perform their own auth handling.
    def self.requires_authentication?
      false
    end

    # Load all available Gql::mutations so that they can be iterated.
    Dir.glob('**/*.rb', base: "#{__dir__}/../mutations/").each do |file|
      subclass = file.sub(%r{.rb$}, '').camelize
      mutation = "Gql::Mutations::#{subclass}".constantize
      next if subclass.starts_with? 'Base' # Ignore base classes.

      field_name = subclass.gsub('::', '').camelize(:lower).to_sym
      field field_name, mutation: mutation
    end
  end
end
