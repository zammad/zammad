# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class UserInfo::Assets
  LEVEL_CUSTOMER = 1
  LEVEL_AGENT    = 2
  LEVEL_ADMIN    = 3

  attr_accessor :current_user_id, :level, :filter_attributes, :user

  def initialize(current_user_id)
    @current_user_id = current_user_id
    @user = User.find_by(id: current_user_id) if current_user_id.present?

    set_level
  end

  def admin?
    check_level?(UserInfo::Assets::LEVEL_ADMIN)
  end

  def agent?
    check_level?(UserInfo::Assets::LEVEL_AGENT)
  end

  def customer?
    check_level?(UserInfo::Assets::LEVEL_CUSTOMER)
  end

  def set_level
    if user.blank?
      self.level = nil
      return
    end

    self.level = UserInfo::Assets::LEVEL_CUSTOMER
    user.permissions_with_child_names.each do |permission|
      case permission
      when %r{^admin\.}
        self.level = UserInfo::Assets::LEVEL_ADMIN
        break
      when 'ticket.agent'
        self.level = UserInfo::Assets::LEVEL_AGENT
      end
    end
  end

  def check_level?(check)
    return true if user.blank?

    level >= check
  end
end
