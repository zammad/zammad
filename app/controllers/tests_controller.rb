# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TestsController < ApplicationController

  prepend_before_action -> { authentication_check_only }

  layout 'tests', except: %i[wait raised_exception]

  def show
    @filename = params[:name]

    if lookup_context.exists? @filename, 'tests'
      render @filename
    elsif @filename.starts_with? 'form'
      render 'form'
    else
      render
    end
  end

  # GET /tests/wait
  def wait
    sleep params[:sec].to_i
    result = { success: true }
    render json: result
  end

  # GET /tests/raised_exception
  def error_raised_exception
    exception = params.fetch(:exception, 'StandardError')
    message   = params.fetch(:message, 'no message provided')

    raise exception.safe_constantize, message
  end

end
