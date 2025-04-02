# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
    search_context = params.fetch(:search_context, {})

    result = [::Ticket, ::Group, ::User, ::Organization].each_with_object({}) do |model, memo|
      param_value = search_context["#{model.name.downcase}_id"]

      next if !param_value

      memo[model.name.downcase.to_sym] = model.find_by(id: param_value)
    end

    result[:user] ||= current_user

    # If ticket does not exist yet, fake it with a customer if present.
    inject_ticket(search_context, result)

    result
  end

  def inject_ticket(search_context, result)
    return if result[:ticket]
    return if !search_context['customer_id']

    customer = ::User.find_by(id: search_context['customer_id'])

    return if !customer

    result[:ticket] = ::Ticket.new(customer: customer)
  end
end
