# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class UploadCachePolicy < ApplicationPolicy

  # UploadCache is currently not restricted other than knowing the form_id
  #   to access the data.
  def show?
    true
  end

  def destroy?
    true
  end

  def user_required?
    false
  end
end
