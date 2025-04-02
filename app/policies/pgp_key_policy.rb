# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class PGPKeyPolicy < ApplicationPolicy
  def create?
    admin?
  end

  def show?
    admin?
  end

  def destroy?
    admin?
  end

  private

  def admin?
    user.permissions?('admin.integration.pgp')
  end
end
