<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSectionMenu from '#mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuLink from '#mobile/components/CommonSectionMenu/CommonSectionMenuLink.vue'
import type { TwoFactorPlugin } from '#shared/entities/two-factor/types.ts'
import type { EnumTwoFactorMethod } from '#shared/graphql/types.ts'

defineProps<{
  methods: TwoFactorPlugin[]
}>()

const emit = defineEmits<{
  (e: 'select', twoFactorMethod: EnumTwoFactorMethod): void
}>()
</script>

<template>
  <CommonSectionMenu>
    <CommonSectionMenuLink
      v-for="method of methods"
      :key="method.name"
      :label="method.label"
      :icon="method.icon.mobile"
      @click="emit('select', method.name)"
    />
  </CommonSectionMenu>
</template>
