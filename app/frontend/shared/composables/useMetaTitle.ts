// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { isString } from 'lodash-es'
import { computed, reactive, watch } from 'vue'

import { i18n } from '#shared/i18n.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

const viewMetaHeader = reactive({
  title: '',
  translateTitle: true,
})

const currentTitle = computed(() => {
  const application = useApplicationStore()
  const productName = application.config.product_name as string

  if (!viewMetaHeader.title) return productName

  const transformedTitle = viewMetaHeader.translateTitle
    ? i18n.t(viewMetaHeader.title)
    : viewMetaHeader.title

  return `${productName} - ${transformedTitle}`
})

const initializeMetaTitle = () => {
  watch(
    currentTitle,
    (newTitle, oldTitle) => {
      if (isString(newTitle) && newTitle !== oldTitle && document)
        document.title = newTitle
    },
    { immediate: true },
  )
}

export default function useMetaTitle() {
  const setViewTitle = (title: string, translate = true) => {
    Object.assign(viewMetaHeader, { title, translateTitle: translate })
  }

  return {
    initializeMetaTitle,
    setViewTitle,
    currentTitle,
  }
}
