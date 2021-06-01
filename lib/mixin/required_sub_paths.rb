# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Mixin
  module RequiredSubPaths

    def self.included(_base)
      path     = caller_locations(1..1).first.path
      sub_path = File.join(File.dirname(path), File.basename(path, '.rb'))
      eager_load_recursive(sub_path)
    end

    # Loads a directory recursively.
    # The specialty of this method is that it will first load all
    # files in a directory and then start with the sub directories.
    # This is needed since otherwise some parent namespaces might not
    # be initialized yet.
    #
    # The cause of this is that Rails autoload doesn't work properly
    # for same named classes or modules in different namespaces.
    # Here is a good description how autoload works:
    # http://urbanautomaton.com/blog/2013/08/27/rails-autoloading-hell/
    #
    # This avoids a) Rails autoloading issues and b) require '...' workarounds
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
