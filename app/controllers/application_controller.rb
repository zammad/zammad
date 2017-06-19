# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
require 'exceptions'

class ApplicationController < ActionController::Base
  include ApplicationController::HandlesErrors
  include ApplicationController::HandlesDevices
  include ApplicationController::HandlesTransitions
  include ApplicationController::Authenticates
  include ApplicationController::SetsHeaders
  include ApplicationController::ChecksMaintainance
  include ApplicationController::RendersModels
  include ApplicationController::HasUser
  include ApplicationController::PreventsCsrf
  include ApplicationController::LogsHttpAccess
  include ApplicationController::ChecksAccess
end
