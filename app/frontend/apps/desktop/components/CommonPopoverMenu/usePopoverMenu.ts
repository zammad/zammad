// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { inject, computed, provide } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import getUuid from '#shared/utils/getUuid.ts'

import type {
  GroupItem,
  MenuItem,
  MenuItems,
  UsePopoverMenuReturn,
} from './types.ts'
import type { Ref } from 'vue'

const POPOVER_MENU_SYMBOL = Symbol('popover-menu')

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

  const filterItems = () => {
    return items.value?.filter((item) => {
      if (item.permission && item.show) {
        return (
          session.hasPermission(item.permission) && item.show(entity?.value)
        )
      }

      if (item.permission) {
        return session.hasPermission(item.permission)
      }

      if (item.show) {
        return item.show(entity?.value)
      }
      return true
    })
  }

  const filteredMenuItems = computed(() => {
    if (!items.value || !items.value.length) return

    const filteredItems = filterItems()

    return filteredItems?.reduce((acc: MenuItems, item) => {
      if (!item.groupLabel) {
        acc.push(item)
        return acc
      }

      const foundedItem = acc.find(
        (group) => group.groupLabel === item.groupLabel,
      )

      const { groupLabel, ...rest } = item

      if (!foundedItem) acc.push({ groupLabel, key: getUuid(), array: [rest] })
      else (foundedItem as GroupItem).array.push(rest)

      return acc
    }, [])
  })

  const singleMenuItemPresent = computed(() => {
    return filteredMenuItems.value?.length === 1
  })

  const singleMenuItem = computed(() => {
    if (!singleMenuItemPresent.value) return

    return filterItems()?.at(0)
  })

  const providePopoverMenu = {
    filteredMenuItems,
    singleMenuItemPresent,
    singleMenuItem,
  }

  if (provides) provide(POPOVER_MENU_SYMBOL, providePopoverMenu)

  return providePopoverMenu
}
