# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::Comment::Attachments < Sequencer::Unit::Import::Zendesk::SubSequence::SubObject

  def process
    # check if we need to import the attachments
    return if skip?

    # if so call the original .process from SubObject class
    super
  end

  private

  # for better readability
  alias remote_attachments resource_collection

  # for better readability
  def local_attachments
    @local_attachments ||= instance.attachments&.filter { |attachment| attachment.preferences&.dig('Content-Disposition') != 'inline' }
  end

  def skip?
    ensure_common_ground
    attachments_equal?
  end

  def ensure_common_ground
    return if attachments_equal?

    local_attachments.each(&:delete)
  end

  def attachments_equal?
    remote_attachments.count == local_attachments.count
  end

  def sequence_name
    "Import::Zendesk::Ticket::Comment::#{resource_klass}"
  end

  def resource_iteration_method
    :each
  end
end
