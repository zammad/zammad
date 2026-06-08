// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'

import type { ObjectDescription } from './types'

export const useFlyoutObjectForm = (name: string, type: EnumObjectManagerObjects) => {
  const flyout = useFlyout({
    name,
    component: () => import('./CommonFlyoutObjectForm.vue'),
  })

  const openFlyoutObjectForm = async (props: ObjectDescription) => {
    return flyout.open({
      name,
      type,
      ...props,
    })
  }

  return { openFlyoutObjectForm }
}
