module UserInfo
  def self.current_user_id
    Thread.current[:user_id]
  end

  def self.current_user_id=(user_id)
    Thread.current[:user_id] = user_id
  end
end
