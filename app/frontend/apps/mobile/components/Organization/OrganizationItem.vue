<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useEditedBy } from '@mobile/composables/useEditedBy'
import CommonOrganizationAvatar from '@shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import { computed, toRef } from 'vue'
import { OrganizationItemData } from './types'

export interface Props {
  entity: OrganizationItemData
}

const props = defineProps<Props>()

const { stringUpdated } = useEditedBy(toRef(props, 'entity'))

const users = computed(() => {
  const { members } = props.entity
  if (!members) return ''

  let usersString = members
    .slice(0, 2)
    .map((user) => {
      return [user.firstname, user.lastname].filter(Boolean).join(' ')
    })
    .join(', ')

  const length = members.length - 2

  if (length > 0) {
    usersString += `, +${length}`
  }

  return usersString
})
</script>

<template>
  <div class="flex">
    <div class="mt-4 w-12">
      <CommonOrganizationAvatar class="bg-gray" :entity="entity" />
    </div>
    <div
      class="flex flex-1 flex-col border-b border-white/10 py-3 text-gray-100"
    >
      <div class="flex">
        <div>
          {{
            entity.ticketsCount === 1
              ? `1 ${$t('ticket')}`
              : $t('%s tickets', entity.ticketsCount)
          }}
        </div>
        <div v-if="users" class="px-1">·</div>
        <div>{{ users }}</div>
      </div>
      <div class="mb-1 text-lg font-bold">
        <slot> {{ entity.name }} </slot>
      </div>
      <div v-if="stringUpdated" data-test-id="stringUpdated" class="text-gray">
        {{ stringUpdated }}
      </div>
    </div>
  </div>
</template>
