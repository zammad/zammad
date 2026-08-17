// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import type { DropdownItem } from '#desktop/components/CommonDropdown/types.ts'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'

// The locale selector of the knowledge base headers. The locale is part of the
//   URL on every knowledge base page, so switching languages is a navigation —
//   the route change is what syncs the store, keeping URL and selector in
//   lockstep. Where to navigate depends on what is open, hence the callback.
export const useKnowledgeBaseHeaderLocales = (onLocaleChange: (localeCode: string) => void) => {
  const { activeLocale, knowledgeBase } = storeToRefs(useKnowledgeBaseStore())

  const localeItems = computed<DropdownItem[]>(
    () =>
      knowledgeBase.value?.kbLocales?.map((kbLocale) => ({
        key: kbLocale.id,
        label: kbLocale.systemLocale.name,
      })) ?? [],
  )

  const activeKbLocale = computed(() =>
    knowledgeBase.value?.kbLocales?.find(
      (kbLocale) => kbLocale.systemLocale.locale === activeLocale.value,
    ),
  )

  const selectedLocaleItem = computed<DropdownItem | undefined>({
    get: () =>
      activeKbLocale.value
        ? { key: activeKbLocale.value.id, label: activeKbLocale.value.systemLocale.name }
        : undefined,
    set: (item) => {
      const match = knowledgeBase.value?.kbLocales?.find((kbLocale) => kbLocale.id === item?.key)

      if (!match) return

      onLocaleChange(match.systemLocale.locale)
    },
  })

  const selectedLocaleCode = computed(
    () => activeKbLocale.value?.systemLocale.locale.toUpperCase() ?? '',
  )

  return { localeItems, selectedLocaleItem, selectedLocaleCode }
}
