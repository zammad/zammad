# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Webhook::PreDefined::RocketChat < Webhook::PreDefined::Mattermost
  def name
    __('Rocket Chat Notifications')
  end
end
