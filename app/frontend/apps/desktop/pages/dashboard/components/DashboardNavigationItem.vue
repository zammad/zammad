<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'

import { useApplicationStore } from '#shared/stores/application.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import {
  navigationIconButtonClass,
  navigationItemClass,
  navigationItemHighlightClass,
} from '#desktop/components/PageNavigation/navigationItemClasses.ts'
import type { NavigationItemComponentProps } from '#desktop/components/PageNavigation/types.ts'

defineProps<NavigationItemComponentProps>()

const router = useRouter()

const application = useApplicationStore()
</script>

<template>
  <template v-if="application.config.dashboard">
    <CommonButton
      v-if="collapsed"
      v-tooltip="$t(route.meta.title)"
      :class="navigationIconButtonClass"
      size="large"
      variant="neutral"
      :icon="route.meta.icon"
      @click="router.push(route.path)"
    />
    <CommonLink
      v-else
      class="hover:no-underline! focus-visible:rounded-lg!"
      :class="[navigationItemClass, { [navigationItemHighlightClass]: active }]"
      :link="route.path"
      :exact-active-class="`w-full ${navigationItemHighlightClass}`"
      internal
    >
      <CommonLabel
        class="gap-2 text-sm! text-current!"
        size="medium"
        :prefix-icon="route.meta.icon"
      >
        {{ $t(route.meta.title) }}
      </CommonLabel>
    </CommonLink>
  </template>
</template>
