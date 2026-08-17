// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
import { computed, toRef, type Ref } from 'vue'

import {
  createLinkClipboardItem,
  useCopyToClipboard,
} from '#shared/composables/useCopyToClipboard.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { initializeActionPlugins } from '#desktop/pages/user/components/UserDetailTopBar/actions/index.ts'

import type { Props } from './TopBarHeaderFull.vue'

export const useTopBarHeader = (props: Ref<Props>) => {
  const { copyToClipboard } = useCopyToClipboard()

  const config = toRef(useApplicationStore(), 'config')

  const copyUserDisplayNameToClipboard = () => {
    copyToClipboard([
      createLinkClipboardItem(
        `${config.value.http_type}://${config.value.fqdn}/desktop/users/${props.value.user.internalId}`,
        props.value.userDisplayName,
      ),
    ])
  }

  const { topLevelActions, secondLevelActions } = initializeActionPlugins()

  const { hasPermission } = useSessionStore()

  const allowedTopLevelActions = computed(() =>
    topLevelActions.filter(
      (item) =>
        (item.permission ? hasPermission(item.permission) : true) &&
        (item.show ? item.show(props.value.user) : true),
    ),
  )

  return {
    copyUserDisplayNameToClipboard,
    allowedTopLevelActions,
    secondLevelActions,
  }
}
