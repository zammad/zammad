<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { transform, deburr } from 'lodash-es'
import { computed, ref } from 'vue'

import { i18n } from '#shared/i18n.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import NavigationMenuFilter from '#desktop/components/NavigationMenu/NavigationMenuFilter.vue'
import NavigationMenuList from '#desktop/components/NavigationMenu/NavigationMenuList.vue'

import type { NavigationMenuCategory, NavigationMenuEntry } from './types'

interface Props {
  categories: NavigationMenuCategory[]
  entries: Record<string, NavigationMenuEntry[]>
  hasNoFiltering?: boolean
}

const props = defineProps<Props>()

const session = useSessionStore()

const permittedEntries = computed(() => {
  return transform(
    props.entries,
    (memo, entries, category) => {
      memo[category] = entries.filter((entry) => {
        if (
          typeof entry.route === 'object' &&
          entry.route.meta?.requiredPermission &&
          !session.hasPermission(entry.route.meta.requiredPermission)
        )
          return false

        if (typeof entry.show === 'function') return entry.show()

        return true
      })
    },
    {} as Record<string, NavigationMenuEntry[]>,
  )
})

const searchText = ref('')

const normalizeString = (input: string) => deburr(input).toLocaleLowerCase()

const searchTextMatcher = computed(() => {
  if (!searchText.value) return ''

  return normalizeString(searchText.value)
})

const isMatchingFilterLabel = (entry: NavigationMenuEntry) => {
  return normalizeString(i18n.t(entry.label)).includes(searchTextMatcher.value)
}

const isMatchingFilterKeywords = (entry: NavigationMenuEntry) => {
  if (!entry.keywords) return false

  return i18n
    .t(entry.keywords)
    .split(',')
    .some((elem) => normalizeString(elem).includes(searchTextMatcher.value))
}

const isMatchingFilter = (entry: NavigationMenuEntry) => {
  return isMatchingFilterLabel(entry) || isMatchingFilterKeywords(entry)
}

const allFilteredEntries = computed<NavigationMenuEntry[]>(() => {
  return Object.values(permittedEntries.value)
    .flat()
    .filter((entry) => isMatchingFilter(entry))
})
</script>

<template>
  <NavigationMenuFilter v-model.trim="searchText" />
  <NavigationMenuList
    v-if="searchText && allFilteredEntries.length > 0"
    :items="allFilteredEntries"
  />
  <CommonLabel
    v-else-if="allFilteredEntries.length == 0"
    class="px-2 py-1 text-stone-200 dark:text-neutral-500"
    >{{ __('No results found') }}
  </CommonLabel>
  <ul v-else>
    <li
      v-for="category in categories"
      :key="category.label"
      class="bg-neutral-00 relative z-0 mb-1"
    >
      <CommonSectionCollapse
        v-if="permittedEntries[category.label].length > 0"
        :id="category.id"
        :title="category.label"
        size="large"
        no-negative-margin
      >
        <template #default="{ headerId }">
          <NavigationMenuList
            :aria-labelledby="headerId"
            :items="permittedEntries[category.label]"
          />
        </template>
      </CommonSectionCollapse>
    </li>
  </ul>
</template>
