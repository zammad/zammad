# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Resources < Sequencer::Unit::Common::Provider::Named
  include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_action :skipped, :failed

  uses :response, :skipped_resource_id

  private

  def resources
    body = JSON.parse(response.body)

    return body if skipped_resource_id.nil?

    # Remove the skipped resource id from the received resources.
    body.reject { |item| item['id'] == skipped_resource_id }
  rescue => e
    logger.error "Won't be continued, because no response is available."
    handle_failure(e)
  end
end
