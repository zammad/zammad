# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Mixin
  module RequiredSubPaths

    def self.included(_base)
      path     = caller_locations(1..1).first.path
      sub_path = File.join(File.dirname(path), File.basename(path, '.rb'))
      eager_load_recursive(sub_path)
    end

    # Loads a directory recursively. This can be needed when accessing
    #   modules not directly via .constantize on a known string, but dynamically
    #   via the inheritance tree, e.g. via .descendants (which assumes they have
    #   previously been loaded).
    def self.eager_load_recursive(path)

      excluded  = ['.', '..']
      sub_paths = []
      Dir.entries(path).each do |entry|
        next if excluded.include?(entry)

        sub_path = File.join(path, entry)

        if File.directory?(sub_path)
          sub_paths.push(sub_path)
        elsif sub_path =~ %r{\A(.*)\.rb\z}
          require_path = $1
          require_dependency(require_path)
        end
      end

      sub_paths.each do |sub_path|
        eager_load_recursive(sub_path)
      end
    end
  end
end
