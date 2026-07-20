<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonDropdown from '#desktop/components/CommonDropdown/CommonDropdown.vue'
import type { DropdownItem } from '#desktop/components/CommonDropdown/types.ts'

import { useTopBarHeader } from './useTopBarHeader.ts'

import type { TopBarHeaderProps } from './types.ts'

const props = defineProps<TopBarHeaderProps>()

const selectedLocale = defineModel<DropdownItem>('selectedLocale')

const { copyKnowledgeBaseNameToClipboard } = useTopBarHeader(toRef(props))
</script>

<template>
  <header
    class="flex w-full items-center gap-x-2 border-b border-neutral-100 bg-neutral-50/80 px-5.5 py-3 backdrop-blur-2xs dark:border-gray-900 dark:bg-gray-500/80"
  >
    <CommonBreadcrumb
      class="flex h-6 grow"
      :items="breadcrumbs"
      size="small"
      emphasize-last-item
      :label="__('Knowledge base navigation')"
    >
      <template #trailing>
        <CommonButton
          v-tooltip="$t('Copy knowledge base name')"
          variant="secondary"
          icon="files"
          size="small"
          class="ms-1"
          @click="copyKnowledgeBaseNameToClipboard"
        />
      </template>
    </CommonBreadcrumb>

    <div
      role="toolbar"
      :aria-label="$t('Knowledge base controls')"
      class="flex items-center gap-2.5"
    >
      <CommonLink
        v-if="previewUrl"
        v-tooltip="$t('View public knowledge base')"
        :link="previewUrl"
        external
        open-in-new-tab
        class="rounded-lg! bg-green-200 p-1 outline outline-offset-0! outline-neutral-100 hover:bg-green-200 hover:outline-blue-600 dark:bg-gray-600 dark:outline-gray-900 dark:hover:bg-gray-600 dark:hover:outline-blue-900"
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
                :class="{
                  'text-white dark:text-white': isOpen,
                  'group-hover:text-black dark:group-hover:text-white': !isOpen,
                }"
                :name="isOpen ? 'chevron-up' : 'chevron-down'"
              />
            </template>
          </CommonButton>
        </template>
      </CommonDropdown>

      <!-- :TODO -->
      <!-- <CommonActionMenu
              button-size="medium"
              role="presentation"
              class="flex! h-full items-center"
              :custom-menu-button-label="$t('Additional actions')"
              no-single-action-mode
              placement="end"
              hide-arrow
            /> -->
    </div>
  </header>
</template>
