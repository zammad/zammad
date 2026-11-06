# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Who made a change in a ticket's history, named as the ticket view's history names it: a person, the system, or what
#   made it instead of a person — also one deleted since, by the name the entry kept.
module Service::AI::Tool::Output::HistoryIssuer
  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable-next Zammad/DetectTranslatableString
  SOURCES = {
    'Trigger'          => 'Trigger',
    'Job'              => 'Scheduler',
    'PostmasterFilter' => 'Postmaster filter',
    'Macro'            => 'Macro',
    'AI::Agent'        => 'AI agent',
  }.freeze

  class << self
    # @param users [Hash{Integer => User}] the users of the page, read once
    # @param readable [#call] whether the reader may see a record, which only then goes out with its type and ID
    def of(entry, users:, readable:)
      entry.sourceable_type.present? ? source(entry) : person(entry.created_by_id, users:, readable:)
    end

    private

    def source(entry)
      label  = SOURCES.fetch(entry.sourceable_type, entry.sourceable_type.demodulize.titleize)
      record = sourceable(entry)
      name   = record&.name.presence || entry.sourceable_name.presence

      { name: [label, name].compact.join(': ') + (record ? '' : ' (deleted)'), source: label, deleted: (true if !record) }.compact
    end

    def sourceable(entry)
      entry.sourceable
    rescue NameError
      nil
    end

    def person(id, users:, readable:)
      return { name: 'System' } if id == Service::AI::Tool::SYSTEM_USER_ID

      user = users[id]
      return { name: 'A deleted user', deleted: true } if !user # rubocop:disable Zammad/DetectTranslatableString
      return { name: user.fullname } if !readable.call(user)

      { type: 'User', id: user.id, name: user.fullname }
    end
  end
end
