# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ApplicationController < ActionController::Base
  include ApplicationController::HandlesErrors
  include ApplicationController::HandlesDevices
  include ApplicationController::HandlesTransitions
  include ApplicationController::Authenticates
  include ApplicationController::SetsHeaders
  include ApplicationController::ChecksMaintenance
  include ApplicationController::RendersModels
  include ApplicationController::HasUser
  include ApplicationController::HasResponseExtentions
  include ApplicationController::PreventsCsrf
  include ApplicationController::HasSecureContentSecurityPolicyForDownloads
  include ApplicationController::LogsHttpAccess
  include ApplicationController::Authorizes
end
