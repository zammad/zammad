# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ExternalDataSourceController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def fetch
    result = Service::ExternalDataSource::Search.execute(
      attribute:      attribute,
      render_context: render_context,
      term:           params[:query],
      limit:          (params[:limit].presence || 10).to_i,
    )

    render json: {
      result: result,
    }
  end

  def preview
    result = Service::ExternalDataSource::Preview.execute(
      data_option:    params[:data_option],
      render_context: render_context,
      term:           params[:query],
      limit:          (params[:limit].presence || 10).to_i,
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

      memo[model.name.downcase.to_sym] = authorized_record(model, param_value)
    end

    result[:user] ||= current_user

    # If ticket does not exist yet, fake it with a customer if present.
    inject_ticket(search_context, result)

    result
  end

  def authorized_record(model, id)
    record = model.find_by(id:)

    return if !record
    return if !authorized?(record, :show?)

    record
  end

  def inject_ticket(search_context, result)
    return if result[:ticket]
    return if !search_context['customer_id']

    customer = authorized_record(::User, search_context['customer_id'])

    return if !customer

    result[:ticket] = ::Ticket.new(customer:)
  end
end
