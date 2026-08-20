<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonDropdown from '#desktop/components/CommonDropdown/CommonDropdown.vue'
import type { DropdownItem } from '#desktop/components/CommonDropdown/types.ts'

import KnowledgeBaseBreadcrumb from './KnowledgeBaseBreadcrumb.vue'
import { useTopBarHeader } from './useTopBarHeader.ts'

import type { TopBarHeaderProps } from './types.ts'

// The row shared by the full and the compact header: breadcrumb, copy button and
//   the controls toolbar. Two root elements, so the full header can keep them as
//   direct children of its grid while the compact header lays them out in a flex row.
const props = withDefaults(
  defineProps<
    TopBarHeaderProps & {
      variant?: 'full' | 'compact'
      copyLabel?: string
    }
  >(),
  {
    variant: 'full',
    copyLabel: __('Copy knowledge base name'),
  },
)

defineOptions({ inheritAttrs: false })

const selectedLocale = defineModel<DropdownItem>('selectedLocale')

const { copyKnowledgeBaseNameToClipboard } = useTopBarHeader(toRef(props))
</script>

<template>
  <KnowledgeBaseBreadcrumb
    :class="variant === 'compact' ? 'flex h-6 grow' : 'flex'"
    :items="breadcrumbs"
    size="small"
    emphasize-last-item
    :label="__('Knowledge base navigation')"
  >
    <template #trailing>
      <CommonButton
        v-if="breadcrumbs.length > 1"
        v-tooltip="$t(copyLabel)"
        variant="secondary"
        icon="files"
        size="small"
        class="ms-1 print:hidden"
        @click="copyKnowledgeBaseNameToClipboard"
      />
    </template>
  </KnowledgeBaseBreadcrumb>

  <div role="toolbar" :aria-label="$t('Knowledge base controls')" class="flex items-center gap-2.5">
    <slot name="stepper" />

    <CommonLink
      v-if="previewUrl"
      v-tooltip="$t('View public knowledge base')"
      :link="previewUrl"
      external
      open-in-new-tab
      class="rounded-lg! bg-green-200 p-1 outline outline-offset-0! outline-neutral-100 hover:bg-green-200 hover:outline-blue-600 dark:bg-gray-600 dark:outline-gray-900 dark:hover:bg-gray-600 dark:hover:outline-blue-900 print:hidden"
      size="small"
    >
      <CommonIcon size="tiny" name="box-arrow-in-up-right" />
    </CommonLink>

    <CommonDropdown v-model="selectedLocale" :items="locales" orientation="bottom">
      <template #trigger="{ toggle, isOpen }">
        <CommonButton
          v-tooltip="$t('Change language')"
          variant="none"
          size="small"
          class="rounded-lg bg-green-200! p-1! outline! outline-offset-0! outline-neutral-100 hover:bg-green-200 dark:bg-gray-600! dark:outline-gray-900 dark:hover:bg-gray-600"
          :class="{ 'outline-blue-800!': isOpen }"
          @click="toggle"
        >
          {{ localeCode }}

          <template #label>
            <span class="truncate">
              {{ localeCode }}
            </span>
            <CommonIcon
              size="xs"
              decorative
              class="text-gray-100 dark:text-neutral-400"
              :name="isOpen ? 'chevron-up' : 'chevron-down'"
            />
          </template>
        </CommonButton>
      </template>
    </CommonDropdown>

    <CommonActionMenu
      v-if="actions?.length"
      :actions="actions"
      button-size="medium"
      role="presentation"
      class="flex! h-full items-center"
      :custom-menu-button-label="$t('Additional actions')"
      no-single-action-mode
      placement="end"
      hide-arrow
    />
  </div>
</template>
