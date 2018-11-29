require 'rbconfig'
require 'shellwords'
require File.expand_path '../arch', __FILE__

module Libv8
  module Paths
    module_function

    def include_paths
      [Shellwords.escape("#{vendored_source_path}/include")]
    end

    def object_paths
      [libv8_object(:base), libv8_object(:snapshot)].map do |path|
        Shellwords.escape path
      end
    end

    def config
      RbConfig::MAKEFILE_CONFIG
    end

    def libv8_object(name)
      filename = "#{libv8_profile}/libv8_#{name}.#{config['LIBEXT']}"
      unless File.exist? filename
        filename = "#{libv8_profile}/obj.target/tools/gyp/libv8_#{name}.#{config['LIBEXT']}"
      end
      return filename
    end

    def libv8_profile
      base = "#{vendored_source_path}/out/#{Libv8::Arch.libv8_arch}"
      debug = "#{base}.debug"
      File.exist?(debug) ? debug : "#{base}.release"
    end

    def vendored_source_path
      File.expand_path "../../../vendor/v8", __FILE__
    end
  end
end
