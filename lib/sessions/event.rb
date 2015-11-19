class Sessions::Event
  include ApplicationLib

  def self.run(event, data, session, client_id)
    adapter = "Sessions::Event::#{event.to_classname}"

    begin
      backend = load_adapter(adapter)
    rescue => e
      return { error: "No such event #{event}" }
    end

    ActiveRecord::Base.establish_connection
    instance = backend.new(data, session, client_id)
    pre = instance.pre
    if pre
      ActiveRecord::Base.remove_connection
      return pre
    end
    result = instance.run
    post = instance.post
    if post
      ActiveRecord::Base.remove_connection
      return post
    end
    result
  end

end
