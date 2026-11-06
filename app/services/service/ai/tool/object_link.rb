# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The link back to an object's own page in Zammad's user interface, for the people who read a tool's result — in the
#   chat, or in an MCP client, which cannot fetch the links, as a page needs a login, so they are data, not resource
#   links. A tool's result names each object by its type and ID, and one class per type in this directory knows its
#   page, and how to name the object without its title — an addon adds its own the same way, without a list to change.
#
# The pages are the current interface's: they open where each user works, as the current interface sends a user who
#   switched on to the desktop view, and the desktop view takes them too.
class Service::AI::Tool::ObjectLink
  class_attribute :object_type, :page_path, instance_accessor: false

  class << self
    # Names an object for a person without its title, which may come from a customer.
    #
    # @param key [String, nil] what the object stands under in the result, such as "customer"
    # @return [String]
    def label(row, key: nil)
      (for_type(row['type']) || self).label_of(row, key:)
    end

    # Overridden by a type that names its objects as people know them.
    def label_of(row, key: nil)
      "#{row['type'].to_s.titleize} #{row['id']}"
    end

    # @param rows [Array<Hash>] objects of a tool's result as JSON, each with its `type` and an Integer `id`
    # @return [Hash{Hash => String}] each row's link, by the row itself; none for an object without a page
    def urls(rows)
      base = "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#"

      rows.group_by { |row| row['type'] }.each_with_object({}.compare_by_identity) do |(type, typed), urls|
        for_type(type)&.pages(typed)&.each { |row, path| urls[row] = "#{base}#{path}" }
      end
    end

    # The link of one object, for a tool that names it outside its rows.
    #
    # @param details [Hash] what else the object's page names, such as the `locale` of a knowledge base answer's text
    # @return [String, nil]
    def url(type:, id:, **details)
      row = { 'type' => type, 'id' => id, **details.stringify_keys }

      urls([row])[row]
    end

    # The pages of a type's rows at once. A type whose page needs more than the ID overrides it and looks up what it
    #   needs for all of them in one query.
    #
    # @return [Hash{Hash => String}] each row's page below the interface's address, by the row itself
    def pages(rows)
      rows.each_with_object({}.compare_by_identity) { |row, pages| pages[row] = format(page_path, id: row['id']) }
    end

    private

    # @param type [String] the type of a row, as the tools name it
    # @param path [String, nil] the page below the interface's address, with %{id} for the object's ID
    def page(type, path = nil)
      self.object_type = type
      self.page_path   = path
    end

    def for_type(type)
      descendants.find { |link| link.object_type == type }
    end
  end

  # Last, because loading the types runs their declarations, which need the methods above.
  include Mixin::RequiredSubPaths
end
