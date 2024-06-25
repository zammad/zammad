<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import type { TemplatesQuery } from '#shared/graphql/types'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types'

interface Props {
  templates?: TemplatesQuery['templates']
}

const emit = defineEmits<{
  selectTemplate: [string]
}>()

const props = defineProps<Props>()

const { popover, popoverTarget, toggle } = usePopover()

const locale = useLocaleStore()

const items = computed(() => {
  const menuItems: MenuItem[] = []

  props.templates?.forEach((template) => {
    menuItems.push({
      key: template.id,
      label: template.name,
      onClick: () => {
        emit('selectTemplate', template.id)
      },
    })
  })

  return menuItems
})

const currentPopoverPlacement = computed(() => {
  if (locale.localeData?.dir === EnumTextDirection.Rtl) return 'start'
  return 'end'
})
</script>

<template>
  <CommonPopover
    ref="popover"
    :owner="popoverTarget"
    :placement="currentPopoverPlacement"
    orientation="top"
  >
    <CommonPopoverMenu :popover="popover" :items="items" />
  </CommonPopover>
  <CommonButton
    ref="popoverTarget"
    size="large"
    suffix-icon="chevron-up"
    variant="secondary"
    @click="toggle(true)"
  >
    {{ $t('Apply Template') }}
  </CommonButton>
</template>
