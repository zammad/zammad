<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

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
    class="inline-flex flex-wrap items-center justify-center divide-x divide-neutral-500 py-2"
  >
    <template v-for="link in links" :key="link.id">
      <CommonLink
        :link="link.link"
        :title="link.description"
        :open-in-new-tab="link.newTab"
        class="my-1 px-2"
        size="medium"
      >
        {{ $t(link.title) }}
      </CommonLink>
    </template>
  </nav>
</template>
