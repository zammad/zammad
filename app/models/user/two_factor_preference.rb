# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class User::TwoFactorPreference < ApplicationModel
  include HasDefaultModelUserRelations

  belongs_to :user, class_name: 'User', touch: true

  store :configuration
end
