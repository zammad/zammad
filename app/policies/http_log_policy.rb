# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class HttpLogPolicy < ApplicationPolicy
  def create?
    permitted?
  end

  def show?
    permitted?
  end

  def permitted?
    facility = if record.respond_to?(:params) && record.params[:facility].present?
                 record.params[:facility]
               elsif record.respond_to?(:facility) && record.facility.present?
                 record.facility
               end

    permission = HttpLog.facility_to_permission(facility)
    permission && user.permissions?(permission)
  end
end
