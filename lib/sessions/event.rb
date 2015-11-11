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
    result = instance.pre_check
    return result if result
    ActiveRecord::Base.establish_connection
    result = instance.run
    ActiveRecord::Base.remove_connection
    result
  end

end
