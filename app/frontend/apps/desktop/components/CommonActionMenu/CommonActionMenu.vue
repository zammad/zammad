<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRefs } from 'vue'

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
  disabled?: boolean
  noSingleActionMode?: boolean
  customMenuButtonLabel?: string
  defaultIcon?: string
  defaultButtonVariant?: ButtonVariant | 'neutral-light' | 'neutral-dark'
}

const props = withDefaults(defineProps<Props>(), {
  buttonSize: 'medium',
  placement: 'arrowStart',
  orientation: 'autoVertical',
  defaultButtonVariant: 'neutral',
  defaultIcon: 'three-dots-vertical',
})

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

const buttonVariantClassExtension = computed(() => {
  const outlineClass = 'outline-offset-0! hover:outline-none!'
  const hoverClass = 'dark:hover:border-blue-700! hover:border-blue-800!'

  if (props.defaultButtonVariant === 'neutral-dark')
    return `${outlineClass} border! border-neutral-100! bg-neutral-50! hover:bg-white! hover:dark:bg-gray-500! text-gray-100! dark:border-gray-900! dark:bg-gray-500! dark:text-neutral-400! ${hoverClass}`

  if (props.defaultButtonVariant === 'neutral-light')
    return `${outlineClass} border! border-neutral-100! bg-blue-100! text-gray-100! dark:border-gray-900! dark:bg-stone-500! dark:text-neutral-400! ${hoverClass}`

  return ''
})

const singleActionMode = computed(() => {
  if (props.noSingleActionMode) return false

  return singleMenuItemPresent.value
})

const variantClasses = computed(() => {
  if (singleMenuItem.value?.variant === 'secondary') return 'text-blue-800!'
  if (singleMenuItem.value?.variant === 'danger') return 'text-red-500!'
  return 'text-stone-200! dark:text-neutral-500!'
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
        class="flex focus:outline-hidden focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800"
        :aria-label="$t(singleActionAriaLabel)"
        :disabled="disabled"
        :link="singleMenuItem.link"
      >
        <CommonIcon
          v-if="singleMenuItem?.icon"
          :size="linkSize"
          :class="variantClasses"
          :name="singleMenuItem?.icon"
        />
      </CommonLink>
      <CommonButton
        v-else
        v-tooltip="$t(singleActionAriaLabel)"
        class="outline-offset-0!"
        :class="variantClasses"
        :size="buttonSize"
        :disabled="disabled"
        :aria-label="$t(singleActionAriaLabel)"
        :icon="singleMenuItem?.icon"
        :icon-class="singleMenuItem?.iconClass"
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
        :disabled="disabled"
        class="outline-offset-0!"
        :class="[
          {
            'outline! outline-blue-800!': popoverIsOpen,
          },
          buttonVariantClassExtension,
        ]"
        :variant="
          defaultButtonVariant !== 'neutral-dark' &&
          defaultButtonVariant !== 'neutral-light'
            ? defaultButtonVariant
            : 'neutral'
        "
        :size="buttonSize"
        :icon="defaultIcon"
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
        <CommonPopoverMenu :entity="entity" :popover="popover" />
      </CommonPopover>
    </template>
  </div>
</template>
