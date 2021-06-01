# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationModel::CanActivityStreamLog
  extend ActiveSupport::Concern

=begin

log activity for this object

  article = Ticket::Article.find(123)
  result = article.activity_stream_log('create', user_id)

  # force log
  result = article.activity_stream_log('create', user_id, true)

returns

  result = true # false

=end

  def activity_stream_log(type, user_id, force = false)

    # return if we run import mode
    return if Setting.get('import_mode')

    # return if we run on init mode
    return if !Setting.get('system_init_done')

    permission = self.class.instance_variable_get(:@activity_stream_permission)
    updated_at = self.updated_at
    if force
      updated_at = Time.zone.now
    end

    attributes = {
      o_id:          self['id'],
      type:          type,
      object:        self.class.name,
      group_id:      self['group_id'],
      permission:    permission,
      created_at:    updated_at,
      created_by_id: user_id,
    }.merge(activity_stream_log_attributes)

    ActivityStream.add(attributes)
  end

  private

  # callback function to overwrite
  # default history stream log attributes
  # gets called from activity_stream_log
  def activity_stream_log_attributes
    {}
  end
end
