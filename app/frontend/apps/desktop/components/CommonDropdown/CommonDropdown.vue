<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type { DropdownItem } from '#desktop/components/CommonDropdown/types.ts'
import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'
import CommonPopoverMenuItem from '#desktop/components/CommonPopoverMenu/CommonPopoverMenuItem.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

interface Props {
  items: MenuItem[]
  orientation?: 'top' | 'bottom'
  /**
   * Will apply on the button label if v-model is not bound
   * */
  actionLabel?: string
}

const props = withDefaults(defineProps<Props>(), {
  orientation: 'bottom',
})

const emit = defineEmits<{
  'handle-action': [DropdownItem]
}>()

const { popover, popoverTarget, isOpen, toggle } = usePopover()

const locale = useLocaleStore()

const currentPopoverPlacement = computed(() => {
  if (locale.localeData?.dir === EnumTextDirection.Rtl) return 'start'
  return 'end'
})

/**
 * MenuItem transformed into a radio button model
 * */
const modelValue = defineModel<DropdownItem>()

const dropdownLabel = computed(() =>
  modelValue.value ? i18n.t(modelValue.value?.label) : props.actionLabel,
)

const handleSelectRadio = (item: DropdownItem) => {
  modelValue.value = item
  toggle()
}

const actionItems = computed(() =>
  props.items.map((item) => ({
    ...item,
    onClick: () => emit('handle-action', item),
  })),
)
</script>

<template>
  <CommonPopover
    ref="popover"
    :owner="popoverTarget"
    :placement="currentPopoverPlacement"
    :orientation="orientation"
  >
    <CommonPopoverMenu v-if="modelValue" :popover="popover" :items="items">
      <template v-for="item in items" :key="item.key" #[`item-${item.key}`]>
        <div class="group flex grow cursor-pointer items-center">
          <CommonPopoverMenuItem
            class="flex grow items-center gap-2 p-2.5"
            :label="item.label"
            :variant="item.variant"
            :link="item.link"
            :icon="item.icon"
            :label-placeholder="item.labelPlaceholder"
            role="checkbox"
            :aria-checked="modelValue.key === item.key"
            @click="handleSelectRadio(item)"
          >
            <template #leading>
              <CommonIcon
                :class="{ 'opacity-0': modelValue.key !== item.key }"
                size="tiny"
                name="check2"
              />
            </template>
          </CommonPopoverMenuItem>
        </div>
      </template>
    </CommonPopoverMenu>
    <CommonPopoverMenu v-else :popover="popover" :items="actionItems" />
  </CommonPopover>

  <CommonButton
    v-bind="$attrs"
    ref="popoverTarget"
    class="group"
    :class="{
      'hover:bg-blue-600 hover:text-black dark:hover:bg-blue-900 dark:hover:text-white':
        !isOpen,
      'bg-blue-800 text-white hover:bg-blue-800': isOpen,
    }"
    size="large"
    variant="secondary"
    @click="toggle"
  >
    <template #label>
      <span class="truncate">
        {{ dropdownLabel }}
      </span>
      <CommonIcon
        size="small"
        decorative
        class="pointer-events-none shrink-0 text-stone-200 transition duration-200 dark:text-neutral-500 dark:group-hover:text-white"
        :class="{
          'text-white dark:text-white': isOpen,
          'group-hover:text-black dark:group-hover:text-white': !isOpen,
        }"
        name="chevron-up"
      />
    </template>
  </CommonButton>
</template>
