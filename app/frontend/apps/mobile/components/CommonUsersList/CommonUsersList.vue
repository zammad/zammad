<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { AvatarUser } from '@shared/components/CommonUserAvatar'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import CommonSectionMenu from '../CommonSectionMenu/CommonSectionMenu.vue'

interface Props {
  users: (AvatarUser & { internalId: number })[]
  totalCount: number
  disableShowMore?: boolean
  label?: string
}

withDefaults(defineProps<Props>(), {
  disableShowMore: false,
})

const emit = defineEmits<{
  (e: 'showMore'): void
}>()
</script>

<template>
  <CommonSectionMenu v-if="users.length" :header-label="label">
    <CommonLink
      v-for="user of users"
      :key="user.id"
      :link="`/users/${user.internalId}`"
      class="flex min-h-[66px] items-center"
    >
      <CommonUserAvatar
        aria-hidden="true"
        :entity="user"
        class="ltr:mr-3 rtl:ml-3"
      />
      <span class="overflow-hidden text-ellipsis whitespace-nowrap">
        {{ user.fullname }}
      </span>
    </CommonLink>
    <button
      v-if="users.length < totalCount"
      class="flex min-h-[54px] items-center justify-center gap-2"
      :class="{
        'cursor-default text-gray-100/50': disableShowMore,
        'text-blue': !disableShowMore,
      }"
      :disabled="disableShowMore"
      @click="emit('showMore')"
    >
      {{ $t('Show %s more', totalCount - users.length) }}
    </button>
  </CommonSectionMenu>
</template>
