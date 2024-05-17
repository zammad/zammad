<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'

import { useEditedBy } from '#mobile/composables/useEditedBy.ts'

import type { UserItemData } from './types.ts'

export interface Props {
  entity: UserItemData
}

const props = defineProps<Props>()

const { stringUpdated } = useEditedBy(toRef(props, 'entity'))
</script>

<template>
  <div class="flex ltr:pr-3 rtl:pl-3">
    <div class="mt-4 flex w-14 justify-center">
      <CommonUserAvatar aria-hidden="true" :entity="entity" />
    </div>
    <div
      class="flex flex-1 flex-col overflow-hidden border-b border-white/10 py-3 text-gray-100"
    >
      <span class="truncate">
        {{
          entity.ticketsCount?.open === 1
            ? `1 ${$t('ticket')}`
            : $t('%s tickets', entity.ticketsCount?.open || 0)
        }}
        <template v-if="entity.organization">
          ·
          {{ entity.organization.name }}
        </template>
      </span>
      <span
        class="mb-1 line-clamp-3 whitespace-normal text-lg font-bold leading-5"
      >
        <slot> {{ entity.firstname }} {{ entity.lastname }} </slot>
      </span>
      <div v-if="stringUpdated" class="truncate" data-test-id="stringUpdated">
        {{ stringUpdated }}
      </div>
    </div>
  </div>
</template>
