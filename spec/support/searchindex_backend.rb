# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rake'

module SearchindexBackendHelper

  class Initialized
    class << self
      attr_accessor :flag
    end
  end

  # Configure ES specific settings in Zammad. Must be done for every test.
  def configure_es_settings
    if ENV['ES_URL'].blank?
      raise "Need ES_URL - hint ES_URL='http://127.0.0.1:9200'"
    end

    if ENV['ES_INDEX'].blank?
      raise "Need ES_INDEX - hint ES_INDEX='estest.local_zammad'"
    end

    Setting.set('es_url',   ENV['ES_URL'])
    Setting.set('es_index', ENV['ES_INDEX'])
    Setting.set('es_attachment_max_size_in_mb', 1)

    return if ENV['ES_USER'].blank? && ENV['ES_PASSWORD'].blank?

    Setting.set('es_user', ENV['ES_USER'])
    Setting.set('es_password', ENV['ES_PASSWORD'])
  end

  def build_indexes
    puts 'Preparing initial Elasticsearch environment...'
    # Just in case, support subseqent runs.
    Rake::Task['zammad:searchindex:drop'].execute
    Rake::Task['zammad:searchindex:create'].execute
  end

  # Remove all existing data of all indexes.
  #   WARNING: don't use in scenarios with shared ES instances.
  def drop_es_content
    # Ensure consistent state before + after dropping data.
    SearchIndexBackend.refresh

    url = "#{Setting.get('es_url')}/_all/_delete_by_query"
    SearchIndexBackend.make_request_and_validate(url, data: { query: { match_all: {} }, }, method: :post)

    # We need to recreate the pipeline.
    SearchIndexBackend.create_pipeline
    SearchIndexBackend.refresh
  end

=begin

reloads the search index for the given models.

  searchindex_model_reload([::Ticket, ::User, ::Organization])

=end

  def searchindex_model_reload(models)
    models.each { |model| model.search_index_reload(silent: true) }
    SearchIndexBackend.refresh
  end
end

RSpec.configure do |config|
  config.include SearchindexBackendHelper, searchindex: true

  # Ensure a state with empty indexes at the start of every test.
  # Tests should use 'searchindex_model_reload' to populate required model indexes.
  config.before(:each, searchindex: true) do

    configure_es_settings # always needed

    if !SearchindexBackendHelper::Initialized.flag
      # First run - create indexes.
      build_indexes
      SearchindexBackendHelper::Initialized.flag = true
      next
    end

    # Was previously run - drop all indexed content.
    drop_es_content
  end
end
