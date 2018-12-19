# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ChecksClientNotification
  extend ActiveSupport::Concern

  included do
    after_create  :notify_clients_after_create
    after_update  :notify_clients_after_update
    after_touch   :notify_clients_after_touch
    after_destroy :notify_clients_after_destroy
  end

=begin

notify_clients_after_create after model got created

used as callback in model file

class OwnModel < ApplicationModel
  after_create    :notify_clients_after_create
  after_update    :notify_clients_after_update
  after_touch     :notify_clients_after_touch
  after_destroy   :notify_clients_after_destroy

  [...]

=end

  def notify_clients_after_create

    # return if we run import mode
    return if Setting.get('import_mode')

    logger.debug { "#{self.class.name}.find(#{id}) notify created #{created_at}" }
    class_name = self.class.name
    class_name.gsub!(/::/, '')
    PushMessages.send(
      message: {
        event: class_name + ':create',
        data:  { id: id, updated_at: updated_at }
      },
      type:    'authenticated',
    )
  end

=begin

notify_clients_after_update after model got updated

used as callback in model file

class OwnModel < ApplicationModel
  after_create    :notify_clients_after_create
  after_update    :notify_clients_after_update
  after_touch     :notify_clients_after_touch
  after_destroy   :notify_clients_after_destroy

  [...]

=end

  def notify_clients_after_update

    # return if we run import mode
    return if Setting.get('import_mode')

    logger.debug { "#{self.class.name}.find(#{id}) notify UPDATED #{updated_at}" }
    class_name = self.class.name
    class_name.gsub!(/::/, '')
    PushMessages.send(
      message: {
        event: class_name + ':update',
        data:  { id: id, updated_at: updated_at }
      },
      type:    'authenticated',
    )
  end

=begin

notify_clients_after_touch after model got touched

used as callback in model file

class OwnModel < ApplicationModel
  after_create    :notify_clients_after_create
  after_update    :notify_clients_after_update
  after_touch     :notify_clients_after_touch
  after_destroy   :notify_clients_after_destroy

  [...]

=end

  def notify_clients_after_touch

    # return if we run import mode
    return if Setting.get('import_mode')

    logger.debug { "#{self.class.name}.find(#{id}) notify TOUCH #{updated_at}" }
    class_name = self.class.name
    class_name.gsub!(/::/, '')
    PushMessages.send(
      message: {
        event: class_name + ':touch',
        data:  { id: id, updated_at: updated_at }
      },
      type:    'authenticated',
    )
  end

=begin

notify_clients_after_destroy after model got destroyed

used as callback in model file

class OwnModel < ApplicationModel
  after_create    :notify_clients_after_create
  after_update    :notify_clients_after_update
  after_touch     :notify_clients_after_touch
  after_destroy   :notify_clients_after_destroy

  [...]

=end
  def notify_clients_after_destroy

    # return if we run import mode
    return if Setting.get('import_mode')

    logger.debug { "#{self.class.name}.find(#{id}) notify DESTOY #{updated_at}" }
    class_name = self.class.name
    class_name.gsub!(/::/, '')
    PushMessages.send(
      message: {
        event: class_name + ':destroy',
        data:  { id: id, updated_at: updated_at }
      },
      type:    'authenticated',
    )
  end
end
