// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { openFlyout, useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'

const FLYOUT_NAME = 'chat-settings'

export const useChatSettingsFlyout = () => {
  useFlyout({
    name: FLYOUT_NAME,
    component: () => import('#desktop/pages/chat/components/ChatSettingsFlyout.vue'),
  })

  const openChatSettingsFlyout = () => openFlyout(FLYOUT_NAME, { name: FLYOUT_NAME })

  return { openChatSettingsFlyout }
}
