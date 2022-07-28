<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { AvatarUser } from '@shared/components/CommonUserAvatar'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'

interface Props {
  user: AvatarUser
}

defineProps<Props>()
</script>

<template>
  <div class="flex flex-1 items-center pb-4 last:pb-0">
    <CommonUserAvatar :entity="user" />

    <div class="ltr:ml-2 rtl:mr-2">{{ user.firstname }}</div>
  </div>
</template>
