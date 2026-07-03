<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRefs } from 'vue'
import { useRouter } from 'vue-router'

import type { Sizes } from '#shared/components/CommonIcon/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import getUuid from '#shared/utils/getUuid.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type { ButtonSize, ButtonVariant } from '#desktop/components/CommonButton/types.ts'
import CommonPopover from '#desktop/components/CommonPopover/CommonPopover.vue'
import type { Orientation, Placement } from '#desktop/components/CommonPopover/types.ts'
import { usePopover } from '#desktop/components/CommonPopover/usePopover.ts'
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
  zIndex?: string
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

const { filteredMenuItems, singleMenuItemPresent, singleMenuItem } = usePopoverMenu(
  actions,
  entity,
  { provides: true },
)

// Generated per component instance instead of derived from the entity, so
// the same entity rendered in multiple places (e.g. compact/full headers) never ends up with duplicate DOM ids.
const instanceId = getUuid()
const menuId = computed(() => `popover-${instanceId}`)

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

const router = useRouter()
</script>

<template>
  <div v-if="filteredMenuItems && filteredMenuItems.length > 0" class="inline-block">
    <template v-if="singleActionMode">
      <CommonLink
        v-if="singleMenuItem?.link"
        v-tooltip="$t(singleActionAriaLabel)"
        class="flex focus-visible-app-default"
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
        @click="singleMenuItem?.onClick?.(props.entity as ObjectLike, router)"
      />
    </template>

    <template v-else>
      <CommonButton
        :id="`action-menu-${instanceId}`"
        ref="popoverTarget"
        v-tooltip="customMenuButtonLabel || $t('Action menu button')"
        aria-haspopup="true"
        :aria-expanded="popoverIsOpen"
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
          defaultButtonVariant !== 'neutral-dark' && defaultButtonVariant !== 'neutral-light'
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
        :z-index="zIndex"
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
