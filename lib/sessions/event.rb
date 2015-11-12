class Sessions::Event
  include ApplicationLib

  def self.run(event, data, session, client_id)
    adapter = "Sessions::Event::#{event.to_classname}"

    begin
      backend = load_adapter(adapter)
    rescue => e
      return { error: "No such event #{event}" }
    end

    instance = backend.new(data, session, client_id)
    pre = instance.pre
    return pre if pre
    ActiveRecord::Base.establish_connection
    result = instance.run
    ActiveRecord::Base.remove_connection
    post = instance.post
    return post if post
    result
  end

end
