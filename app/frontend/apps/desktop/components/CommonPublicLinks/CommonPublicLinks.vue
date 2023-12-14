<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

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
    class="py-3 justify-center items-center gap-x-2 flex-wrap inline-flex"
  >
    <template v-for="link in links" :key="link.id">
      <CommonLink
        :link="link.link"
        :title="link.description"
        :open-in-new-tab="link.newTab"
        class="text-blue-800 text-sm after:ml-2 after:font-medium after:text-neutral-500 after:content-['|'] last:after:content-none"
      >
        {{ $t(link.title) }}
      </CommonLink>
    </template>
  </nav>
</template>
