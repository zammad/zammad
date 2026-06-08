# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class HttpLogPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope

    def resolve(facility: nil)
      if facility.present?
        permission = HttpLog.facility_to_permission(facility)
        return scope.none if !user.permissions?(permission)

        return scope.where(facility:)
      end

      facilities = (HttpLog.facilities_permission_lookup.values.uniq & user.permissions_with_child_names)
        .flat_map { |permission| HttpLog.facilities_by_permission[permission] }
        .compact

      facilities.any? ? scope.where(facility: facilities) : scope.none
    end
  end
end
