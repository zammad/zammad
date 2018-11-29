require 'date'
require 'forwardable'
require 'set'

module Clavius
  class << self

    extend Forwardable

    def configure(&block)
      Thread.current[:clavius_schedule] = Schedule.new(&block)
    end

    delegate %i[
      weekdays
      included
      excluded
      before
      after
      active?
      days
      between
    ] => :schedule

    private

    def schedule
      Thread.current[:clavius_schedule] or
        fail 'Clavius has not been configured.'
    end

  end
end

require 'clavius/calculation'
require 'clavius/configuration'
require 'clavius/schedule'
require 'clavius/time'
require 'clavius/version'
