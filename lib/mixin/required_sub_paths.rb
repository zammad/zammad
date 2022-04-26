# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Mixin
  module RequiredSubPaths

    def self.included(base)
      path     = caller_locations(1..1).first.path
      sub_path = File.join(File.dirname(path), File.basename(path, '.rb'))
      eager_load_recursive(base, sub_path)
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
