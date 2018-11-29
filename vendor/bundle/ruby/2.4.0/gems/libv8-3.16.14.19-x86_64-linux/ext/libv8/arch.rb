require 'rbconfig'

module Libv8
  module Arch
    module_function

    def x86_64_from_build_cpu
      RbConfig::MAKEFILE_CONFIG['build_cpu'] == 'x86_64'
    end

    def x86_64_from_byte_length
      ['foo'].pack('p').size == 8
    end

    def x86_64_from_arch_flag
      RbConfig::MAKEFILE_CONFIG['ARCH_FLAG'] =~ /x86_64/
    end

    def rubinius?
      Object.const_defined?(:RUBY_ENGINE) && RUBY_ENGINE == "rbx"
    end

    # TODO fix false positive on 64-bit ARM
    def x64?
      if rubinius?
        x86_64_from_build_cpu || x86_64_from_arch_flag
      else
        x86_64_from_byte_length
      end
    end

    def arm?
      RbConfig::MAKEFILE_CONFIG['build_cpu'] =~ /^arm/
    end

    def libv8_arch
      if arm? then "arm"
      elsif x64? then "x64"
      else "ia32"
      end
    end
  end
end
