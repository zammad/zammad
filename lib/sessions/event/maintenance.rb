class Sessions::Event::Maintenance < Sessions::Event::Base

  def initialize(params)
    super(params)
    return if !@is_web_socket
    ActiveRecord::Base.establish_connection
  end

  def destroy
    return if !@is_web_socket
    ActiveRecord::Base.remove_connection
  end

  def run

    # check if sender is admin
    return if !role_permission_check('Admin', 'maintenance')
    Sessions.broadcast(@payload, 'public', @session['id'])
    false
  end

end
