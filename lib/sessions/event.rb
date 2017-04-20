class Sessions::Event
  include ApplicationLib

  def self.run(params)
    adapter = "Sessions::Event::#{params[:event].to_classname}"

    begin
      backend = load_adapter(adapter)
    rescue => e
      return { event: 'error', data: { error: "No such event #{params[:event]}", payload: params[:payload] } }
    end

    begin
      instance = backend.new(params)
      result = instance.run
      instance.destroy
      result
    rescue => e
      return { event: 'error', data: { error: e.message, payload: params[:payload] } }
    end
  end

end
