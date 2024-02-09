// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import useMetaTitle from '#shared/composables/useMetaTitle.ts'

export const useSetTitle = () => {
  const { setViewTitle } = useMetaTitle()
  const title = ref('')

  const setTitle = (newTitle: string) => {
    title.value = newTitle

    setViewTitle(newTitle)
  }

  return { title, setTitle }
}
