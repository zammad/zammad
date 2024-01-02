# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::CoreWorkflow::Readonly < FormUpdater::CoreWorkflow::Backend
  def perform
    perform_result[:readonly].each do |name, readonly|
      result[name] ||= {}

      result[name][:disabled] = readonly
    end

    # Currently a special handling for the body field, because in the desktop view it's
    # really connected to the body field, so it should always have the same readonly/disabled state.
    handle_attachments_field
  end

  private

  def handle_attachments_field
    return if !result['body']&.key?(:disabled)

    result['attachments'] ||= {}
    result['attachments'][:disabled] = result['body'][:disabled]
  end
end
