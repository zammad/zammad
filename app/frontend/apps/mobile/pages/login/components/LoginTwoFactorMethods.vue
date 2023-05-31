<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSectionMenu from '#mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuLink from '#mobile/components/CommonSectionMenu/CommonSectionMenuLink.vue'
import type { TwoFactorPlugin } from '#shared/entities/two-factor/types.ts'
import type { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'

defineProps<{
  methods: TwoFactorPlugin[]
  recoveryCodesAvailable: boolean
}>()

const emit = defineEmits<{
  (e: 'select', twoFactorMethod: EnumTwoFactorAuthenticationMethod): void
  (e: 'use-recovery-code'): void
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
  <button
    v-if="recoveryCodesAvailable"
    class="mb-6 w-full max-w-md text-center font-semibold text-gray"
    @click="emit('use-recovery-code')"
  >
    {{ $t('Or use one of your recovery codes.') }}
  </button>
</template>
