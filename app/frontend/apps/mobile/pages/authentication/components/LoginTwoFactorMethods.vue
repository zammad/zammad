<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { TwoFactorPlugin } from '#shared/entities/two-factor/types.ts'
import type { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'

import CommonSectionMenu from '#mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuLink from '#mobile/components/CommonSectionMenu/CommonSectionMenuLink.vue'

defineProps<{
  methods: TwoFactorPlugin[]
  recoveryCodesAvailable: boolean
}>()

const emit = defineEmits<{
  select: [twoFactorMethod: EnumTwoFactorAuthenticationMethod]
  'use-recovery-code': []
}>()
</script>

<template>
  <CommonSectionMenu>
    <CommonSectionMenuLink
      v-for="method of methods"
      :key="method.name"
      :label="method.label"
      :icon="method.icon"
      @click="emit('select', method.name)"
    />
  </CommonSectionMenu>
  <button
    v-if="recoveryCodesAvailable"
    class="text-gray mb-6 w-full max-w-md text-center font-semibold"
    @click="emit('use-recovery-code')"
  >
    {{ $t('Or use one of your recovery codes.') }}
  </button>
</template>
