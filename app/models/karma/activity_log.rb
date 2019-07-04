# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Karma::ActivityLog < ApplicationModel
  belongs_to :object_lookup, optional: true

  self.table_name = 'karma_activity_logs'

=begin

add karma activity log of an object

  Karma::ActivityLog.add('ticket create', User.find(1), 'Ticket', 123)

=end

  def self.add(action, user, object, o_id, force = false)
    activity = Karma::Activity.lookup(name: action)

    if object
      object_id = ObjectLookup.by_name(object)
    end

    Karma::ActivityLog.transaction do
      last_activity = Karma::ActivityLog.where(user_id: user.id).order(id: :desc).lock(true).first
      latest_activity = Karma::ActivityLog.where(
        user_id:          user.id,
        object_lookup_id: object_id,
        o_id:             o_id,
        activity_id:      activity.id,
      ).find_by('created_at >= ?', Time.zone.now - activity.once_ttl.seconds)
      return false if !force && latest_activity

      score_total = 0
      if last_activity
        score_total = last_activity.score_total
      end

      local_score_total = score_total + activity.score
      if local_score_total.negative?
        local_score_total = 0
      end

      Karma::ActivityLog.create(
        object_lookup_id: object_id,
        o_id:             o_id,
        user_id:          user.id,
        activity_id:      activity.id,
        score:            activity.score,
        score_total:      local_score_total,
      )
    end

    # set new karma level
    Karma::User.sync(user)

    true
  end

=begin

remove whole karma activity log of an object

  Karma::ActivityLog.remove('Ticket', 123)

=end

  def self.remove(object_name, o_id)
    object_id = ObjectLookup.by_name(object_name)
    Karma::ActivityLog.where(
      object_lookup_id: object_id,
      o_id:             o_id,
    ).destroy_all
  end

  def self.latest(user, limit = 12)
    result = []
    logs = Karma::ActivityLog.where(user_id: user.id).order(id: :desc).limit(limit)
    logs.each do |log|
      last = result.last
      if last && last[:object_id] == log.object_id && last[:o_id] == log.o_id && last[:created_at] == log.created_at
        comment = {
          description: Karma::Activity.lookup(id: log.activity_id).description,
          score:       log.score,
        }
        last[:comments].push comment
        last[:score_total] = score_total
        next
      end
      comment = {
        object_id:   log.object_id,
        o_id:        log.o_id,
        description: Karma::Activity.lookup(id: log.activity_id).description,
        score:       log.score,
      }
      data = {
        comments:    [comment],
        score_total: log.score_total,
        created_at:  log.created_at,
      }
      result.push data
    end
    result
  end

end
