# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ExternalDataSourceController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def fetch
    result = Service::ExternalDataSource::Search.new.execute(
      attribute:      attribute,
      render_context: render_context,
      term:           params[:query],
      limit:          params[:limit].to_i || 10,
    )

    render json: {
      result: result,
    }
  end

  def preview
    result = Service::ExternalDataSource::Preview.new.execute(
      data_option:    params[:data_option],
      render_context: render_context,
      term:           params[:query],
      limit:          params[:limit].to_i || 10,
    )

    render json: result
  end

  private

  def attribute
    ::ObjectManager::Attribute.get(object: params[:object], name: params[:attribute]).tap do |attribute|
      raise "Could not find object attribute for #{params}." if !attribute
    end
  end

  def render_context
    {}.tap do |result|
      search_context = params.fetch(:search_context, {})
      [::Ticket, ::Group, ::User, ::Organization].each do |model|
        param_value = search_context["#{model.name.downcase}_id"]
        result[model.name.downcase.to_sym] = model.find_by(id: param_value) if param_value
      end

      result[:user] ||= current_user

      # If ticket does not exist yet, fake it with a customer if present.
      inject_ticket(search_context, result)
    end
  end

  def inject_ticket(search_context, result)
    return if result[:ticket]

    customer = ::User.find_by(id: search_context['customer_id']) if search_context['customer_id']
    result[:ticket] = ::Ticket.new(customer: customer) if customer

  end
end
