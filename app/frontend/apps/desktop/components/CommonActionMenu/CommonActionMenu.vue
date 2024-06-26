<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, toRefs } from 'vue'

import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import type {
  Orientation,
  Placement,
} from '#shared/components/CommonPopover/types.ts'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import getUuid from '#shared/utils/getUuid.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type { ButtonSize } from '#desktop/components/CommonButton/types.ts'
import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import { usePopoverMenu } from '#desktop/components/CommonPopoverMenu/usePopoverMenu.ts'

export interface Props {
  actions: MenuItem[]
  entity?: ObjectLike
  buttonSize?: ButtonSize
  placement?: Placement
  orientation?: Orientation
  noSingleActionMode?: boolean
  customMenuButtonLabel?: string
}

const props = withDefaults(defineProps<Props>(), {
  buttonSize: 'medium',
  placement: 'arrowStart',
  orientation: 'autoVertical',
})

const popoverMenu = ref<InstanceType<typeof CommonPopoverMenu>>()

const { popover, isOpen: popoverIsOpen, popoverTarget, toggle } = usePopover()

const { actions, entity } = toRefs(props)
const { filteredMenuItems, singleMenuItemPresent, singleMenuItem } =
  usePopoverMenu(actions, entity, { provides: true })

const entityId = computed(() => props.entity?.id || getUuid())
const menuId = computed(() => `popover-${entityId.value}`)

const singleActionAriaLabel = computed(() => {
  if (typeof singleMenuItem.value?.ariaLabel === 'function') {
    return singleMenuItem.value.ariaLabel(props.entity)
  }

  return singleMenuItem.value?.ariaLabel || singleMenuItem.value?.label
})

const singleActionMode = computed(() => {
  if (props.noSingleActionMode) return false

  return singleMenuItemPresent.value
})

const buttonVariantClass = computed(() => {
  if (singleMenuItem.value?.variant === 'secondary') return 'text-blue-800'
  if (singleMenuItem.value?.variant === 'danger') return 'text-red-500'
  return 'text-stone-200 dark:text-neutral-500'
})
</script>

<template>
  <div
    v-if="filteredMenuItems && filteredMenuItems.length > 0"
    class="inline-block"
  >
    <CommonButton
      v-if="singleActionMode"
      :class="buttonVariantClass"
      :size="buttonSize"
      :aria-label="$t(singleActionAriaLabel)"
      :icon="singleMenuItem?.icon"
      @click="singleMenuItem?.onClick?.(entity as ObjectLike)"
    />
    <template v-else>
      <CommonButton
        :id="`action-menu-${entityId}`"
        ref="popoverTarget"
        :aria-label="$t(customMenuButtonLabel || 'Action menu button')"
        aria-haspopup="true"
        :aria-controls="popoverIsOpen ? menuId : undefined"
        class="text-stone-200 dark:text-neutral-500"
        :class="{
          'outline outline-1 outline-offset-1 outline-blue-800': popoverIsOpen,
        }"
        :size="buttonSize"
        icon="three-dots-vertical"
        @click="toggle"
      />

      <CommonPopover
        :id="menuId"
        ref="popover"
        :placement="placement"
        :orientation="orientation"
        :owner="popoverTarget"
      >
        <CommonPopoverMenu
          ref="popoverMenu"
          :entity="entity"
          :popover="popover"
        />
      </CommonPopover>
    </template>
  </div>
</template>
