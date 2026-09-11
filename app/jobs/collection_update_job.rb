# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CollectionUpdateJob < ApplicationJob
  include HasActiveJobLock

  def lock_key
    # "CollectionUpdateJob/:model"
    "#{self.class.name}/#{arguments[0]}"
  end

  def perform(model)
    model = model.safe_constantize
    return if model.blank?

    recipients = session_recipients
    return if recipients.blank?

    # resolved for every session at once: one level per role set beats one per session, and a
    #   user that no longer exists is simply absent from it
    levels   = UserInfo::Assets.levels_for(recipients.map(&:last))
    payloads = {}

    recipients.each do |client_id, user_id|
      level = levels[user_id]
      next if level.blank?

      # check permission based access
      if model.collection_push_permission_value.present?
        user = User.lookup(id: user_id)
        next if !user&.permissions?(model.collection_push_permission_value)
      end

      payloads[level] = build_payload(model, level) if !payloads.key?(level)
      next if payloads[level].blank?

      push(client_id, model, user_id, payloads[level])
    end

  end

  private

  # [[client_id, user_id], ...] of the sessions that name a user at all
  def session_recipients
    Sessions.list.filter_map do |client_id, data|
      next if client_id.blank?

      user_id = data&.dig(:user, 'id')
      next if user_id.blank?

      [client_id, user_id]
    end
  end

  def push(client_id, model, user_id, payload)
    Rails.logger.debug { "push assets for push_collection #{model} for user #{user_id}" }
    Sessions.send(client_id, {
                    data:  payload[:assets],
                    event: 'loadAssets',
                  })

    Rails.logger.debug { "push push_collection #{model} for user #{user_id}" }
    Sessions.send(client_id, {
                    event: 'resetCollection',
                    data:  {
                      model.to_app_model => payload[:all],
                    },
                  })
  end

  # The job runs without a user context, so the assets field scopes (e.g. Group::Assets, which
  #   keeps a group's note and user_ids from customers) would see no audience and pass everything
  #   through. Build one payload per assets level present among the sessions instead — three at
  #   most, rather than one per session — and hand each session the one for its own level.
  #
  # Note that this scopes the attributes of each record, not the set of records: the level says
  #   what an audience may see of a record, but not which records a single recipient may see at
  #   all. Per-record checks like Group::Assets#authorized_asset? are per user, so honouring them
  #   would mean one payload per session. The push therefore still lists every record of the
  #   model, as it always has.
  def build_payload(model, level)
    assets = {}
    all    = []

    UserInfo.with_assets_level(level) do
      model.reorder(id: :asc).find_each do |record|
        assets = record.assets(assets)
        all.push collection_attributes(record)
      end
    end

    return if all.blank?

    { assets:, all: }
  end

  # Collections are pushed to every session allowed to see the model, so their sensitive values
  #   must be masked like in the assets.
  def collection_attributes(record)
    attributes = record.attributes_with_association_ids

    return attributes if !record.respond_to?(:mask_sensitive_values)

    record.mask_sensitive_values(attributes, record)
  end
end
