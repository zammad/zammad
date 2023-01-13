# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Sequencer::Unit::Import::Zendesk::SubSequence::Base
  module ClassMethods

    def resource_klass
      @resource_klass ||= name.split('::').last.singularize
    end
  end

  def self.included(base)
    base.extend(ClassMethods)

    base.uses :dry_run, :import_job, :field_map
  end

  private

  def default_params
    {
      dry_run:    dry_run,
      import_job: import_job,
      field_map:  field_map,
    }
  end

  def resource_klass
    # base.instance_delegate [:resource_klass] => base
    # doesn't work since we are included and then inherited
    # there might be multiple inherited hooks which overwrite
    # each other :/
    self.class.resource_klass
  end

  def sequence_name
    "Import::Zendesk::#{resource_klass}"
  end

  def resource_iteration(&)
    resource_collection.public_send(resource_iteration_method, &)
  rescue ZendeskAPI::Error::NetworkError, Faraday::SSLError => e
    return if expected_exception?(e)
    raise if !retry_exception?(e)
    raise if (fail_count ||= 1) > 10

    logger.error e
    logger.info "Sleeping 10 seconds after ZendeskAPI::Error::NetworkError and retry (##{fail_count}/10)."
    sleep 10

    fail_count += 1
    retry
  end

  # #2262 Zendesk-Import fails for User & Organizations when 403 "access" denied
  def expected_exception?(e)
    status = e.response&.status.to_s
    return false if !status || status != '403'

    %w[UserField OrganizationField].include?(resource_klass)
  end

  def retry_exception?(e)
    e.is_a?(Faraday::SSLError) || !(200..399).cover?(e&.response&.status)
  end

  def resource_collection
    @resource_collection ||= collection_provider.public_send(resource_collection_attribute)
  end

  def resource_iteration_method
    :all!
  end

  def resource_collection_attribute
    @resource_collection_attribute ||= resource_klass.pluralize.underscore
  end
end
