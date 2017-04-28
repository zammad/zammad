module UserInfo
  def self.current_user_id
    Thread.current[:user_id]
  end

  def self.current_user_id=(user_id)
    Thread.current[:user_id] = user_id
  end

  def self.ensure_current_user_id
    if UserInfo.current_user_id.nil?
      UserInfo.current_user_id = 1
      reset_current_user_id    = true
    end

    yield

    return if !reset_current_user_id
    UserInfo.current_user_id = nil
  end
end
