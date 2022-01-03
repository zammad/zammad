// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import useApplicationConfigStore from '@common/stores/application/config'
import { computed, reactive, watch } from 'vue'
import { isString } from 'lodash-es'
import { i18n } from '@common/utils/i18n'

const viewMetaHeader = reactive({
  title: '',
  translateTitle: true,
})

const currentTitle = computed(() => {
  const config = useApplicationConfigStore()
  const productName = config.get('product_name') as string

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
