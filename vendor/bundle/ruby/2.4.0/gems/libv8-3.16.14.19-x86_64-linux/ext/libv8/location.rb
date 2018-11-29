require 'yaml'
require 'pathname'
require File.expand_path '../paths', __FILE__

module Libv8
  class Location
    def install!
      File.open(Pathname(__FILE__).dirname.join('.location.yml'), "w") do |f|
        f.write self.to_yaml
      end
      return 0
    end

    def self.load!
      File.open(Pathname(__FILE__).dirname.join('.location.yml')) do |f|
        YAML.load f
      end
    end

    class Vendor < Location
      def install!
        require File.expand_path '../builder', __FILE__
        builder = Libv8::Builder.new
        exit_status = builder.build_libv8!
        super if exit_status == 0
        verify_installation!
        return exit_status
      end
      def configure(context = MkmfContext.new)
        context.incflags.insert 0, Libv8::Paths.include_paths.map{|p| "-I#{p}"}.join(" ")  + " "
        context.ldflags.insert 0, Libv8::Paths.object_paths.join(" ") + " "
      end

      def verify_installation!
        Libv8::Paths.object_paths.each do |p|
          fail ArchiveNotFound, p unless File.exist? p
        end
      end

      class ArchiveNotFound < StandardError
        def initialize(filename)
          super "libv8 did not install properly, expected binary v8 archive '#{filename}'to exist, but it was not found"
        end
      end
    end

    class System < Location
      def configure(context = MkmfContext.new)
        context.send(:dir_config, 'v8')
        context.send(:find_header, 'v8.h') or fail NotFoundError
        context.send(:have_library, 'v8') or fail NotFoundError
      end

      class NotFoundError < StandardError
        def initialize(*args)
          super(<<-EOS)
By using --with-system-v8, you have chosen to use the version 
of V8 found on your system and *not* the one that is bundled with 
the libv8 rubygem. 

However, your system version of v8 could not be located. 

Please make sure your system version of v8 that is compatible 
with #{Libv8::VERSION} installed. You may need to use the 
--with-v8-dir option if it is installed in a non-standard location
EOS
        end
      end
    end

    class MkmfContext
      def incflags
        $INCFLAGS
      end

      def ldflags
        $LDFLAGS
      end
    end
  end
end
