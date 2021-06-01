# rubocop:disable Naming/FileName
# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

if Kernel.respond_to?(:open_uri_original_open)
  module Kernel

    module_function

    # see: https://github.com/ruby/ruby/pull/1675
    def open(name, *rest, &block)
      if name.respond_to?(:open) && name.method(:open).parameters.present?
        name.open(*rest, &block)
      elsif name.respond_to?(:to_str) &&
            %r{\A[A-Za-z][A-Za-z0-9+\-.]*://} =~ name &&
            (uri = URI.parse(name)).respond_to?(:open)
        uri.open(*rest, &block)
      else
        open_uri_original_open(name, *rest, &block)
      end
    end
  end
end
# rubocop:enable Naming/FileName
