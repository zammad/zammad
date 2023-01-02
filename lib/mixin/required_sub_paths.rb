# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Mixin
  module RequiredSubPaths

    def self.included(base)
      base_path     = ActiveSupport::Dependencies.search_for_file base.name.underscore
      backends_path = base_path.delete_suffix File.extname(base_path)
      eager_load_recursive(base, backends_path)
    end

    # Loads a directory recursively. This can be needed when accessing
    #   modules not directly via .constantize on a known string, but dynamically
    #   via the inheritance tree, e.g. via .descendants (which assumes they have
    #   previously been loaded).
    def self.eager_load_recursive(base, path)

      excluded = ['.', '..']
      Dir.entries(path).each do |entry|
        next if excluded.include?(entry)

        sub_path = File.join(path, entry)
        namespace = "#{base}::#{entry.sub(%r{.rb$}, '').camelize}"
        if File.directory?(sub_path)
          eager_load_recursive(namespace, sub_path)
        elsif entry.ends_with?('.rb')
          namespace.constantize
        end
      end

    end
  end
end
