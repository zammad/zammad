<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

const emit = defineEmits<{
  search: [query: string]
}>()

const { config } = storeToRefs(useApplicationStore())

const AI_GENERATED_TAG = 'ai-generated'

const searchFor = (query: string) => () => emit('search', query)

// The same labels, query syntax and order as the legacy list
//   (search_field_widget.coffee:25-41), so both stacks suggest the same searches.
const shortcuts = computed<MenuItem[]>(() => [
  {
    key: 'user-documentation',
    label: __('User documentation'),
    link: 'https://next.zammad.org/documentation/use/guides/knowledge-base.html#Search',
    linkExternal: true,
    openInNewTab: true,
  },
  {
    key: 'created-at',
    label: __('Created within last 14 days'),
    onClick: searchFor('created_at:>now-14d'),
    show: () => !!config.value.es_enabled,
  },
  {
    key: 'edited-at',
    label: __('Updated within last 3 days'),
    onClick: searchFor('edited_at:>now-3d'),
    show: () => !!config.value.es_enabled,
  },
  {
    key: 'ai-generated',
    label: __('Tagged %s'),
    labelPlaceholder: [AI_GENERATED_TAG],
    onClick: searchFor(`tags:${AI_GENERATED_TAG}`),
    show: () =>
      !!config.value.es_enabled && config.value.ai_assistance_kb_answer_from_ticket_generation,
  },
  {
    key: 'drafts',
    label: __('Drafts only'),
    onClick: searchFor('publication_state:draft'),
    show: () => !!config.value.es_enabled,
  },
])
</script>

<template>
  <CommonActionMenu
    class="print:hidden"
    no-single-action-mode
    :actions="shortcuts"
    :custom-menu-button-label="$t('Suggested searches')"
    :header-label="__('Suggested searches')"
    button-size="small"
    default-icon="lightbulb"
    default-button-variant="tertiary"
    placement="arrowEnd"
  />
</template>
