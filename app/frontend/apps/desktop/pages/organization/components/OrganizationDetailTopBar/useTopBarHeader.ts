// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRef } from 'vue'

import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { initializeActionPlugins } from './actions/index.ts'

import type { Props } from './TopBarHeaderFull.vue'
import type { Ref } from 'vue'

export const useTopBarHeader = (props: Ref<Props>) => {
  const { copyToClipboard } = useCopyToClipboard()

  const config = toRef(useApplicationStore(), 'config')

  const copyOrganizationDisplayNameToClipboard = () => {
    copyToClipboard([
      new ClipboardItem({
        'text/plain': props.value.organizationDisplayName,
        'text/html': `<a href="${config.value.http_type}://${config.value.fqdn}/desktop/organizations/${props.value.organization.internalId}">${props.value.organizationDisplayName}</a>`,
      }),
    ])
  }

  const { topLevelActions, secondLevelActions } = initializeActionPlugins()

  const { hasPermission } = useSessionStore()

  const allowedTopLevelActions = computed(() =>
    topLevelActions.filter(
      (item) =>
        (item.permission ? hasPermission(item.permission) : true) &&
        (item.show ? item.show(props.value.organization) : true),
    ),
  )

  return {
    copyOrganizationDisplayNameToClipboard,
    allowedTopLevelActions,
    secondLevelActions,
  }
}
