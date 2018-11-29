require 'libv8/version'
require 'libv8/location'

module Libv8
  def self.configure_makefile
    location = Location.load!
    location.configure
  end
end
