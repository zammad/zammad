class Observer::UserDeviceLogJob
  def initialize(http_user_agent, remote_ip, user_id, fingerprint, type)
    @http_user_agent = http_user_agent
    @remote_ip = remote_ip
    @user_id = user_id
    @fingerprint = fingerprint
    @type = type
  end

  def perform
    UserDevice.add(
      @http_user_agent,
      @remote_ip,
      @user_id,
      @fingerprint,
      @type,
    )
  end
end
