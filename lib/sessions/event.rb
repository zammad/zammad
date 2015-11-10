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
      result = backend.run(data, session, client_id)
      ActiveRecord::Base.remove_connection
      result
  end

end