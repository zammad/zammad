module Mixin
  module RailsLogger
    extend Forwardable
    extend SingleForwardable

    instance_delegate [:logger] => self
    single_delegate   [:logger] => :Rails
  end
end
