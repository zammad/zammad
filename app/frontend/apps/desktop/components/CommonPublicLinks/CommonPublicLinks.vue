<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { usePublicLinks } from '#shared/composables/usePublicLinks.ts'
import { EnumPublicLinksScreen } from '#shared/graphql/types.ts'

interface Props {
  screen: EnumPublicLinksScreen
}
const props = defineProps<Props>()
const { links } = usePublicLinks(props.screen)
</script>

<template>
  <nav
    v-if="links.length"
    class="inline-flex flex-wrap items-center justify-center py-2 divide-x divide-neutral-500"
  >
    <template v-for="link in links" :key="link.id">
      <CommonLink
        :link="link.link"
        :title="link.description"
        :open-in-new-tab="link.newTab"
        class="px-2 my-1"
        size="medium"
      >
        {{ $t(link.title) }}
      </CommonLink>
    </template>
  </nav>
</template>
