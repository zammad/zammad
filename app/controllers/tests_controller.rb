# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class TestsController < ApplicationController

  # GET /test/wait
  def wait
    sleep params[:sec].to_i
    result = { success: true }
    render json: result
  end

  # GET /test/unprocessable_entity
  def error_unprocessable_entity
    raise Exceptions::UnprocessableEntity, 'some error message'
  end

  # GET /test/not_authorized
  def error_not_authorized
    raise Exceptions::NotAuthorized, 'some error message'
  end

  # GET /test/ar_not_found
  def error_ar_not_found
    raise ActiveRecord::RecordNotFound, 'some error message'
  end

  # GET /test/standard_error
  def error_standard_error
    raise StandardError, 'some error message'
  end

  # GET /test/argument_error
  def error_argument_error
    raise ArgumentError, 'some error message'
  end

end
