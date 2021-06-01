# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event
  include ApplicationLib

  def self.run(params)
    begin
      backend = "Sessions::Event::#{params[:event].to_classname}".constantize
    rescue => e
      Rails.logger.error e.inspect
      Rails.logger.error e.backtrace
      return { event: 'error', data: { error: "No such event #{params[:event]}: #{e.inspect}", payload: params[:payload] } }
    end

    begin
      instance = backend.new(params)
      result = instance.run
      instance.destroy
      result
    rescue => e
      Rails.logger.error e.inspect
      Rails.logger.error e.backtrace
      { event: 'error', data: { error: e.message, payload: params[:payload] } }
    end
  end

end
