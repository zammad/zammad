# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::User::OverviewSortingsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('user_preferences.overview_sorting')
end
