# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::ChecksUserColumnsFillup
  extend ActiveSupport::Concern

  included do
    before_create :fill_up_user_create
    before_update :fill_up_user_update
  end

=begin

set created_by_id & updated_by_id if not given based on UserInfo (current session)

Used as before_create callback, no own use needed

  result = Model.fill_up_user_create(params)

returns

  result = params # params with updated_by_id & created_by_id if not given based on UserInfo (current session)

=end

  def fill_up_user_create
    if self.class.column_names.include? 'updated_by_id'
      if UserInfo.current_user_id
        if updated_by_id && updated_by_id != UserInfo.current_user_id
          logger.info "NOTICE create - self.updated_by_id is different: #{updated_by_id}/#{UserInfo.current_user_id}"
        end
        self.updated_by_id = UserInfo.current_user_id
      end
    end

    return true if !self.class.column_names.include? 'created_by_id'

    return true if !UserInfo.current_user_id

    if created_by_id && created_by_id != UserInfo.current_user_id
      logger.info "NOTICE create - self.created_by_id is different: #{created_by_id}/#{UserInfo.current_user_id}"
    end
    self.created_by_id = UserInfo.current_user_id
    true
  end

=begin

set updated_by_id if not given based on UserInfo (current session)

Used as before_update callback, no own use needed

  result = Model.fill_up_user_update(params)

returns

  result = params # params with updated_by_id & created_by_id if not given based on UserInfo (current session)

=end

  def fill_up_user_update
    return true if !self.class.column_names.include? 'updated_by_id'
    return true if !UserInfo.current_user_id

    self.updated_by_id = UserInfo.current_user_id
    true
  end
end
