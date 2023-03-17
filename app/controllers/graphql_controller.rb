# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class GraphqlController < ApplicationController
  # Handled in the GraphQL processing, not on controller level.
  skip_before_action :verify_csrf_token

  prepend_before_action lambda {
    begin
      authentication_check_only
    rescue Exceptions::Forbidden
      # Don't throw if the user is not authenticated. Just continue without a current_user.
    end
  }

  def execute
    if params[:_json]
      return render json: multiplex
    end

    render json: single_query
  rescue => e
    raise e if !Rails.env.development?

    handle_error_in_development(e)
  end

  private

  def multiplex
    queries = params[:_json].map do |param|
      {
        query:          param[:query],
        operation_name: param[:operationName],
        variables:      prepare_variables(param[:variables]),
        context:        context
      }
    end
    Gql::ZammadSchema.multiplex(queries)
  end

  def single_query
    query = params[:query]
    variables = prepare_variables(params[:variables])
    operation_name = params[:operation_name]

    Gql::ZammadSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
  end

  def context
    # context must be kept in sync with GraphqlChannel!
    {
      sid:          session.id,
      current_user: current_user,
      # :controller is used by login/logout mutations and MUST NOT be used otherwise.
      controller:   self,
    }
  end

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }, status: :internal_server_error
  end
end
