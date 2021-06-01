# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Karma::User < ApplicationModel
  self.table_name = 'karma_users'

  def self.sync(user)
    score = Karma.score_by_user(user)
    level = level_by_score(score)
    record = Karma::User.find_by(user_id: user.id)
    if record
      return record if record.score == score && record.level == level

      record.score = score
      record.level = level
      record.save
      return record
    end
    Karma::User.create!(
      user_id: user.id,
      level:   level,
      score:   score,
    )
  end

  def self.by_user(user)
    record = Karma::User.find_by(user_id: user.id)
    return record if record

    sync(user)
  end

  def self.level_by_score(score)
    level = nil
    karma_levels = Setting.get('karma_levels')
    karma_levels.each do |local_level|
      if !level
        level = local_level[:name]
      end
      next if local_level[:start] && score < local_level[:start]
      next if local_level[:end] && score > local_level[:end]

      level = local_level[:name]
    end
    level
  end

end
