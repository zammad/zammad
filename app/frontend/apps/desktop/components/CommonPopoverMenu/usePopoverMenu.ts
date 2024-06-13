// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { inject, computed, provide } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

import type { ComputedRef, Ref } from 'vue'

const POPOVER_MENU_SYMBOL = Symbol('popover-menu')

interface UsePopoverMenuReturn {
  filteredMenuItems: ComputedRef<MenuItem[] | undefined>
  singleMenuItemPresent: ComputedRef<boolean>
  singleMenuItem: ComputedRef<MenuItem | undefined>
}

export const usePopoverMenu = (
  items: Ref<MenuItem[] | undefined>,
  entity: Ref<ObjectLike | undefined>,
  options: { provides?: boolean } = {},
) => {
  const injectPopoverMenu = inject<Maybe<UsePopoverMenuReturn>>(
    POPOVER_MENU_SYMBOL,
    null,
  )

  if (injectPopoverMenu) return injectPopoverMenu

  const { provides = false } = options

  const session = useSessionStore()

  const filteredMenuItems = computed(() => {
    if (!items.value || !items.value.length) return

    return items.value.filter((item) => {
      if (item.permission) {
        return session.hasPermission(item.permission)
      }

      if (item.show) {
        return item.show(entity?.value)
      }

      return true
    })
  })

  const singleMenuItemPresent = computed(() => {
    return filteredMenuItems.value?.length === 1
  })

  const singleMenuItem = computed(() => {
    if (!singleMenuItemPresent.value) return

    return filteredMenuItems.value?.[0]
  })

  const providePopoverMenu = {
    filteredMenuItems,
    singleMenuItemPresent,
    singleMenuItem,
  }

  if (provides) provide(POPOVER_MENU_SYMBOL, providePopoverMenu)

  return providePopoverMenu
}
