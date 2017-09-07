module ApplicationController::ChecksAccess
  extend ActiveSupport::Concern

  private

  def access!(instance, access)
    instance.access!(current_user, access)
  end
end
