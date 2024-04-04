<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useApplicationStore } from '#shared/stores/application.ts'

const application = useApplicationStore()
</script>

<template>
  <footer
    class="text-gray mt-8 flex w-full max-w-md items-center justify-center border-t border-gray-600 py-2.5 align-middle font-medium leading-4"
  >
    <CommonLink
      v-if="application.hasCustomProductBranding"
      link="https://zammad.org"
      external
      open-in-new-tab
      class="ltr:mr-1 rtl:ml-1"
    >
      <img
        :src="'/assets/images/icons/logo.svg'"
        :alt="$t('Logo')"
        class="h-6 w-6"
      />
    </CommonLink>
    <span class="ltr:mr-1 rtl:ml-1">{{ $t('Powered by') }}</span>
    <CommonLink
      link="https://zammad.org"
      external
      open-in-new-tab
      class="font-semibold"
    >
      {{ $t('Zammad') }}
    </CommonLink>
  </footer>
</template>
