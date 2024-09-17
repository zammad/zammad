// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ComputedRef } from 'vue'

export const useBubbleStyleGuide = (
  position: ComputedRef<'left' | 'right'>,
  isArticleTypeNote: ComputedRef<boolean>,
) => {
  const bodyClasses = computed(() =>
    position.value === 'right'
      ? ['dark:bg-stone-500', 'bg-blue-100']
      : ['dark:bg-gray-400', 'bg-neutral-100'],
  )

  const dividerClass = computed(() => {
    if (position.value === 'right')
      return 'border-t border-t-neutral-100 dark:border-t-gray-900'

    return 'border-t border-t-neutral-300 dark:border-t-gray-900'
  })

  const frameBorderClass = computed(() => {
    if (isArticleTypeNote.value) return ''

    if (position.value === 'right')
      return 'border border-neutral-100 dark:border-gray-900'

    return 'border border-neutral-300 dark:border-gray-900'
  })

  const headerAndIconBarBackgroundClass = computed(() =>
    position.value === 'right'
      ? ['dark:bg-stone-700', 'bg-blue-300']
      : ['dark:bg-gray-500', 'bg-neutral-50'],
  )

  // We need this class otherwise on a transition the edges of children are shown
  const articleWrapperBorderClass = computed(() =>
    position.value === 'right'
      ? 'ltr:rounded-br-none rtl:rounded-bl-none'
      : 'ltr:rounded-bl-none rtl:rounded-br-none',
  )

  const internalNoteClass = computed(() => {
    if (!isArticleTypeNote.value) return ''

    // Uses `.bg-stripes` class which is defined in `app/frontend/apps/desktop/styles/main.css`.
    return position.value === 'right'
      ? 'bg-stripes before:rounded-2xl relative z-0 rounded-xl outline outline-1 outline-blue-700 ltr:rounded-br-none rtl:rounded-bl-none ltr:before:rounded-br-none rtl:before:rounded-bl-none'
      : 'bg-stripes before:rounded-2xl relative z-0 rounded-xl outline outline-1 outline-blue-700 ltr:rounded-bl-none rtl:rounded-br-none ltr:before:rounded-bl-none rtl:before:rounded-br-none'
  })

  return {
    bodyClasses,
    dividerClass,
    frameBorderClass,
    headerAndIconBarBackgroundClass,
    articleWrapperBorderClass,
    internalNoteClass,
  }
}
