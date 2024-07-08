<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, toRefs } from 'vue'

import type { Sizes } from '#shared/components/CommonIcon/types.ts'
import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import type {
  Orientation,
  Placement,
} from '#shared/components/CommonPopover/types.ts'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import getUuid from '#shared/utils/getUuid.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type {
  ButtonSize,
  ButtonVariant,
} from '#desktop/components/CommonButton/types.ts'
import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import { usePopoverMenu } from '#desktop/components/CommonPopoverMenu/usePopoverMenu.ts'

export interface Props {
  actions: MenuItem[]
  entity?: ObjectLike
  buttonSize?: ButtonSize
  linkSize?: Sizes
  placement?: Placement
  orientation?: Orientation
  hideArrow?: boolean
  noSingleActionMode?: boolean
  customMenuButtonLabel?: string
  defaultIcon?: string
  defaultButtonVariant?: ButtonVariant
}

const props = withDefaults(defineProps<Props>(), {
  buttonSize: 'medium',
  placement: 'arrowStart',
  orientation: 'autoVertical',
  defaultButtonVariant: 'neutral',
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

const variantClasses = computed(() => {
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
    <template v-if="singleActionMode">
      <CommonLink
        v-if="singleMenuItem?.link"
        v-tooltip="$t(singleActionAriaLabel)"
        class="flex"
        :aria-label="$t(singleActionAriaLabel)"
        :link="singleMenuItem.link"
      >
        <CommonIcon
          :size="linkSize"
          :class="variantClasses"
          :name="singleMenuItem?.icon"
        />
      </CommonLink>
      <CommonButton
        v-else
        v-tooltip="$t(singleActionAriaLabel)"
        class="rounded-sm p-0"
        :class="[variantClasses]"
        :size="buttonSize"
        :aria-label="$t(singleActionAriaLabel)"
        :icon="singleMenuItem?.icon"
        @click="singleMenuItem?.onClick?.(props.entity as ObjectLike)"
      />
    </template>

    <template v-else>
      <CommonButton
        :id="`action-menu-${entityId}`"
        ref="popoverTarget"
        :aria-label="$t(customMenuButtonLabel || 'Action menu button')"
        aria-haspopup="true"
        :aria-controls="popoverIsOpen ? menuId : undefined"
        class="rounded-sm !p-0"
        :class="{
          'outline outline-1 outline-offset-1 outline-blue-800': popoverIsOpen,
        }"
        :variant="defaultButtonVariant"
        :size="buttonSize"
        :icon="defaultIcon || 'three-dots-vertical'"
        @click="toggle"
      />

      <CommonPopover
        :id="menuId"
        ref="popover"
        :placement="placement"
        :hide-arrow="hideArrow"
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
