// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed, ref } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useUserCurrentLocaleMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentLocale.api.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import MutationHandler from '../server/apollo/handler/MutationHandler.ts'

const ZAMMAD_TRANSLATION_LINK = 'https://translations.zammad.org/'

export const useLocaleUpdate = () => {
  const isSavingLocale = ref(false)

  const localeMutation = new MutationHandler(useUserCurrentLocaleMutation({}), {
    errorNotificationMessage: __('The language could not be updated.'),
  })

  const { notify } = useNotifications()

  const localeStore = useLocaleStore()
  const { localeData, locales } = storeToRefs(localeStore)
  const { setLocale } = localeStore

  const modelCurrentLocale = computed({
    get: () => localeData.value?.locale ?? 'en',
    set: (locale) => {
      if (!locale || localeData.value?.locale === locale) return
      isSavingLocale.value = true
      Promise.all([setLocale(locale), localeMutation.send({ locale })])
        .then(() => {
          notify({
            id: 'locale-update',
            message: __('Profile language updated successfully.'),
            type: NotificationTypes.Success,
          })
        })
        .finally(() => {
          isSavingLocale.value = false
        })
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
