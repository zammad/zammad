<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useEditedBy } from '@mobile/composables/useEditedBy'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { toRef } from 'vue'
import type { UserItemData } from './types'

export interface Props {
  entity: UserItemData
}

const props = defineProps<Props>()

const { stringUpdated } = useEditedBy(toRef(props, 'entity'))
</script>

<template>
  <div class="flex">
    <div class="mt-4 w-12">
      <CommonUserAvatar :entity="entity" />
    </div>
    <div
      class="flex flex-1 flex-col border-b border-white/10 py-3 text-gray-100"
    >
      <div class="flex">
        <div v-if="entity.organization">{{ entity.organization.name }}</div>
        <div v-if="entity.organization" class="px-1">·</div>
        <div>
          {{
            entity.ticketsCount === 1
              ? `1 ${$t('ticket')}`
              : $t('%s tickets', entity.ticketsCount)
          }}
        </div>
      </div>
      <div class="mb-1 text-lg">
        <slot> {{ entity.firstname }} {{ entity.lastname }} </slot>
      </div>
      <div v-if="stringUpdated" class="text-gray" data-test-id="stringUpdated">
        {{ stringUpdated }}
      </div>
    </div>
  </div>
</template>
