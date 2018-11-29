require 'rake'
require 'rake/tasklib'
require 'autoprefixer-rails'

module Rake
  # Define task to inspect Autoprefixer browsers, properties and values.
  # Call it from your `Rakefile`:
  #
  #   AutoprefixerTasks.new(['> 1%', 'opera 12'])
  class AutoprefixerTasks < Rake::TaskLib
    attr_reader :browsers

    def initialize(params = {})
      @params    = params
      @processor = AutoprefixerRails.processor(@params)
      define
    end

    def define
      namespace :autoprefixer do
        desc 'Show selected browsers and prefixed CSS properties and values'
        task :info do
          puts @processor.info
        end
      end
    end
  end
end
