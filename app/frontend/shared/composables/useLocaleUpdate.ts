// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'
import { storeToRefs } from 'pinia'

import { useAccountLocaleMutation } from '#shared/entities/account/graphql/mutations/locale.api.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import MutationHandler from '../server/apollo/handler/MutationHandler.ts'

const ZAMMAD_TRANSLATION_LINK = 'https://translations.zammad.org/'

export const useLocaleUpdate = () => {
  const isSavingLocale = ref(false)

  const localeMutation = new MutationHandler(useAccountLocaleMutation({}), {
    errorNotificationMessage: __('The language could not be updated.'),
  })

  const localeStore = useLocaleStore()
  const { localeData, locales } = storeToRefs(localeStore)
  const { setLocale } = localeStore

  const modelCurrentLocale = computed({
    get: () => localeData.value?.locale ?? 'en',
    set: (locale) => {
      if (!locale || localeData.value?.locale === locale) return
      isSavingLocale.value = true
      Promise.all([setLocale(locale), localeMutation.send({ locale })]).finally(
        () => {
          isSavingLocale.value = false
        },
      )
    },
  })

  const localeOptions = computed(() => {
    return (
      locales?.value?.map((locale) => {
        return { label: locale.name, value: locale.locale }
      }) || []
    )
  })

  return {
    translation: {
      link: ZAMMAD_TRANSLATION_LINK,
    },
    isSavingLocale,
    modelCurrentLocale,
    localeOptions,
  }
}
