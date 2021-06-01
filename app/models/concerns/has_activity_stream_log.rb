# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasActivityStreamLog
  extend ActiveSupport::Concern

  included do
    after_create   :activity_stream_create
    after_update   :activity_stream_update
    before_destroy :activity_stream_destroy
  end

=begin

log object create activity stream, if configured - will be executed automatically

  model = Model.find(123)
  model.activity_stream_create

=end

  def activity_stream_create
    activity_stream_log('create', self['created_by_id'])
    true
  end

=begin

log object update activity stream, if configured - will be executed automatically

  model = Model.find(123)
  model.activity_stream_update

=end

  def activity_stream_update
    return true if !saved_changes?

    ignored_attributes  = self.class.instance_variable_get(:@activity_stream_attributes_ignored) || []
    ignored_attributes += %i[created_at updated_at created_by_id updated_by_id]

    log = false
    saved_changes.each_key do |key|
      next if ignored_attributes.include?(key.to_sym)

      log = true
    end
    return true if !log

    activity_stream_log('update', self['updated_by_id'])
    true
  end

=begin

delete object activity stream, will be executed automatically

  model = Model.find(123)
  model.activity_stream_destroy

=end

  def activity_stream_destroy
    ActivityStream.remove(self.class.to_s, id)
    true
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

serve method to ignore model attributes in activity stream and/or limit activity stream permission

class Model < ApplicationModel
  include HasActivityStreamLog
  activity_stream_permission 'admin.user'
  activity_stream_attributes_ignored :create_article_type_id, :preferences
end

=end

    def activity_stream_attributes_ignored(*attributes)
      @activity_stream_attributes_ignored = attributes
    end

    def activity_stream_permission(permission)
      @activity_stream_permission = permission
    end
  end
end
