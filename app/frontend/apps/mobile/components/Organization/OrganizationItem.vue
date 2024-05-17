<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import CommonOrganizationAvatar from '#shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'

import { useEditedBy } from '#mobile/composables/useEditedBy.ts'

import type { OrganizationItemData } from './types.ts'

export interface Props {
  entity: OrganizationItemData
}

const props = defineProps<Props>()

const { stringUpdated } = useEditedBy(toRef(props, 'entity'))

const users = computed(() => {
  const { members } = props.entity
  if (!members) return ''

  const users = members.edges
    .map((edge) => edge.node.fullname)
    .filter((fullname) => fullname && fullname !== '-')
    .slice(0, 2)

  let usersString = users.join(', ')

  const length = members.totalCount - users.length

  if (length > 0) {
    usersString += `, +${length}`
  }

  return usersString
})
</script>

<template>
  <div class="flex ltr:pr-3 rtl:pl-3">
    <div class="mt-4 flex w-14 justify-center">
      <CommonOrganizationAvatar
        aria-hidden="true"
        class="bg-gray"
        :entity="entity"
      />
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
        <template v-if="users">
          ·
          {{ users }}
        </template>
      </span>
      <span
        class="mb-1 line-clamp-3 whitespace-normal text-lg font-bold leading-5"
      >
        <slot> {{ entity.name }} </slot>
      </span>
      <div
        v-if="stringUpdated"
        data-test-id="stringUpdated"
        class="text-gray truncate"
      >
        {{ stringUpdated }}
      </div>
    </div>
  </div>
</template>
