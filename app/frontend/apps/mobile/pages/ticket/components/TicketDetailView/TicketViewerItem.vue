<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { AvatarUser } from '#shared/components/CommonUserAvatar/types.ts'
import { EnumTaskbarApp } from '#shared/graphql/types.ts'

interface Props {
  user: AvatarUser
  editing: boolean
  idle?: boolean
  app: EnumTaskbarApp
}

const props = defineProps<Props>()

const showDesktopIcon = computed(() => {
  return props.app === EnumTaskbarApp.Desktop
})

const idleClasses = computed(() => {
  return props.idle !== undefined && props.idle ? 'opacity-20 grayscale' : ''
})
</script>

<template>
  <div class="flex items-center justify-between px-3 first:pt-1 last:pb-1">
    <div class="flex items-center">
      <CommonUserAvatar :entity="user" :class="idleClasses" />
      <div class="ltr:ml-3 rtl:mr-3">{{ user.fullname }}</div>
    </div>

    <div v-if="editing || showDesktopIcon" class="flex items-center">
      <CommonIcon
        v-if="editing && showDesktopIcon"
        :label="__('Editing on Desktop')"
        name="desktop-edit"
      />
      <CommonIcon
        v-else-if="showDesktopIcon"
        :label="__('Desktop')"
        name="desktop"
      />
      <CommonIcon v-else-if="editing" :label="__('Editing')" name="edit" />
    </div>
  </div>
</template>
