# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::KnowledgeBase::Answer::Update::Validator
  # Saving replays the form's upload cache onto the answer, and
  #   CanCloneAttachments#attach_upload_cache deletes every non-inline attachment before re-creating
  #   them from that cache. So a cache seeded before somebody else added a file does not merely miss
  #   their file - it deletes it, silently and completely.
  #
  # Refused rather than merged: the base is only known to the client (the list it was seeded with),
  #   and without it a foreign addition is indistinguishable from a removal by this editor. The
  #   client sends that baseline as `known_attachments` and may resubmit with this exception skipped,
  #   which is the deliberate overwrite.
  #
  # Compared by name and size, not by id: the cache holds *copies* of the answer's files, created by
  #   `clone_attachments`, so their Store ids are not the answer's and cannot be matched up.
  class ConcurrentAttachmentChange < Base

    def valid!
      # Nothing to replay means nothing to delete - see Service::KnowledgeBase::Answer::Base#attach_files.
      return if answer_data[:form_id].blank?

      # A client that sends no baseline cannot be checked. Deliberately not an error: the mutation is
      #   also used without a form (an integration, a script), and those have no seeded cache to be
      #   stale.
      return if answer_data[:known_attachments].nil?

      return if stored_attachments == known_attachments

      raise Error
    end

    class Error < Service::KnowledgeBase::Answer::Update::Validator::BaseError
      def initialize
        super(__('The attachments of this answer were changed by someone else in the meantime.'))
      end
    end

    private

    def stored_attachments
      identities(
        answer.attachments.reject(&:inline?).map { |file| { name: file.filename, size: file.size.to_i } }
      )
    end

    def known_attachments
      identities(
        answer_data[:known_attachments].map { |file| { name: file[:name], size: file[:size].to_i } }
      )
    end

    # A multiset, so two files of the same name and size are one change apart rather than equal, and
    #   the order the client happens to send them in does not matter.
    def identities(files)
      files.tally.sort_by { |identity, _count| [identity[:name], identity[:size]] }
    end
  end
end
