# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rake'

# if you make changes, then please also change this file 'test/support/searchindex_helper.rb'
# this is required as long as our test suite is made of RSpec and MiniTest
module SearchindexBackendHelper

  def self.included(base)
    # Execute in RSpec class context
    base.class_exec do

      after(:each) do
        next if ENV['ES_URL'].blank?

        Rake::Task['searchindex:drop'].execute
      end
    end
  end

=begin

prepares elasticsearch

@param required [Boolean] raises error if ES is not configured. Recommended to avoid mysterious errors in CI.
@param rebuild  [Boolean] rebuilds indexes and sleeps for 1 second after given yield block is executed

@yield given block run after ES is setup, but before index rebuilding

=end
  def configure_elasticsearch(required: false, rebuild: false)
    if ENV['ES_URL'].blank?
      return if !required

      raise "Need ES_URL - hint ES_URL='http://127.0.0.1:9200'"
    end

    Setting.set('es_url', ENV['ES_URL'])

    # Setting.set('es_url', 'http://127.0.0.1:9200')
    # Setting.set('es_index', 'estest.local_zammad')
    # Setting.set('es_user', 'elasticsearch')
    # Setting.set('es_password', 'zammad')

    if ENV['ES_INDEX_RAND'].present?
      rand_id          = ENV.fetch('CI_JOB_ID', "r#{rand(999)}")
      test_method_name = self.class.description.gsub(%r{[^\w]}, '_')
      ENV['ES_INDEX']  = "es_index_#{test_method_name.downcase}_#{rand_id}_#{rand(999_999_999)}"
    end
    if ENV['ES_INDEX'].blank?
      raise "Need ES_INDEX - hint ES_INDEX='estest.local_zammad'"
    end

    Setting.set('es_index', ENV['ES_INDEX'])

    # set max attachment size in mb
    Setting.set('es_attachment_max_size_in_mb', 1)

    yield if block_given?

    return if !rebuild

    rebuild_searchindex
  end

  def rebuild_searchindex
    Rake::Task.clear
    Zammad::Application.load_tasks
    Rake::Task['searchindex:rebuild'].execute
    Rake::Task['searchindex:refresh'].execute
  end

end

# configure_elasticsearch has to be executed manually!!!
RSpec.configure do |config|
  config.include SearchindexBackendHelper, searchindex: true
end
