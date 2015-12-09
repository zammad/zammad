class Sessions::Event
  include ApplicationLib

  def self.run(params)
    adapter = "Sessions::Event::#{params[:event].to_classname}"

    begin
      backend = load_adapter(adapter)
    rescue => e
      return { error: "No such event #{params[:event]}" }
    end

    instance = backend.new(params)
    result = instance.run
    instance.destroy
    result
  end

end
