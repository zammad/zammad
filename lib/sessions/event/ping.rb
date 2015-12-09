class Sessions::Event::Ping < Sessions::Event::Base

  def run
    {
      event: 'pong',
    }
  end

end
