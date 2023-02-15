<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */

import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { storeToRefs } from 'pinia'
import { MutationHandler, QueryHandler } from '@shared/server/apollo/handler'
import { useSessionStore } from '@shared/stores/session'
import { usePWASupport, isStandalone } from '@shared/utils/pwa'
import { useLocaleStore } from '@shared/stores/locale'
import { browser, os } from '@shared/utils/browser'
import FormGroup from '@shared/components/Form/FormGroup.vue'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useProductAboutQuery } from '@shared/graphql/queries/about.api'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuLink from '@mobile/components/CommonSectionMenu/CommonSectionMenuLink.vue'
import CommonSectionPopup from '@mobile/components/CommonSectionPopup/CommonSectionPopup.vue'
import { useRawHTMLIcon } from '@shared/components/CommonIcon'
import { i18n } from '@shared/i18n'
import { useAccountLocaleMutation } from '../graphql/mutations/locale.api'

const router = useRouter()

const logout = () => {
  router.push('/logout')
}

const session = useSessionStore()
const { user } = storeToRefs(session)

const localeStore = useLocaleStore()
const savingLocale = ref(false)

const locales = computed(() => {
  return (
    localeStore.locales?.map((locale) => {
      return { label: locale.name, value: locale.locale }
    }) || []
  )
})

const localeMutation = new MutationHandler(useAccountLocaleMutation({}), {
  errorNotificationMessage: __('The language could not be updated.'),
})

const currentLocale = computed({
  get: () => localeStore.localeData?.locale ?? null,
  set: (locale) => {
    // don't update if locale is the same
    if (
      !locale ||
      savingLocale.value ||
      localeStore.localeData?.locale === locale
    )
      return
    savingLocale.value = true
    Promise.all([
      localeStore.setLocale(locale),
      localeMutation.send({ locale }),
    ]).finally(() => {
      savingLocale.value = false
    })
  },
})

const hasVersionPermission = session.hasPermission('admin.version')

const productAboutQuery = new QueryHandler(
  useProductAboutQuery({ enabled: hasVersionPermission }),
  { errorNotificationMessage: __('The product version could not be fetched.') },
)

const productAbout = productAboutQuery.result()

const isMobileIOS = browser.name?.includes('Safari') && os.name?.includes('iOS')
const { canInstallPWA, installPWA } = usePWASupport()
const showInstallButton = computed(
  () => !isStandalone && (canInstallPWA.value || isMobileIOS),
)

const showInstallIOSPopup = ref(false)
const installPWAMessage = computed(() => {
  const iconShare = useRawHTMLIcon({
    class: 'inline-flex text-blue',
    decorative: true,
    size: 'small',
    name: 'mobile-ios-share',
  })

  const iconAdd = useRawHTMLIcon({
    class: 'inline-flex',
    decorative: true,
    size: 'small',
    name: 'mobile-add-square',
  })

  return i18n.t(
    __(
      'To install %s as an app, press the %s "Share" button and then the %s "Add to Home Screen" button.',
    ),
    __('Zammad'),
    iconShare,
    iconAdd,
  )
})

const installZammadPWA = () => {
  if (isStandalone) return

  // on chromium this will show a chrome popup with native "install" button
  if (canInstallPWA.value) {
    installPWA()
    return
  }

  // on iOS we cannot install it with native functionality, so we show
  // instructions on how to install it
  // let's pray Apple will add native functionality in the future
  if (isMobileIOS) {
    showInstallIOSPopup.value = true
  }
}
</script>

<template>
  <div class="px-4">
    <div v-if="user" class="flex flex-col items-center justify-center py-6">
      <div>
        <CommonUserAvatar :entity="user" size="xl" personal />
      </div>
      <div class="mt-2 text-xl font-bold">
        {{ user.firstname }} {{ user.lastname }}
      </div>
      <!-- TODO email -->
    </div>

    <!-- TODO maybe instead of a different page we can use a Dialog? -->
    <CommonSectionMenu v-if="session.hasPermission('user_preferences.avatar')">
      <CommonSectionMenuLink
        :icon="{ name: 'mobile-person', size: 'base' }"
        icon-bg="bg-pink"
        link="/account/avatar"
      >
        {{ $t('Avatar') }}
      </CommonSectionMenuLink>
    </CommonSectionMenu>

    <!--
      TODO: no-options-label-translation is not working currently, therefore we need to explicitly set it to true
    -->
    <FormGroup v-if="session.hasPermission('user_preferences.language')">
      <FormKit
        v-model="currentLocale"
        type="treeselect"
        :label="__('Language')"
        :options="locales"
        :disabled="savingLocale"
        :no-options-label-translation="true"
        sorting="label"
      />

      <template #help>
        {{ $t('Did you know? You can help translating %s at:', 'Zammad') }}
        <CommonLink class="text-blue" link="https://translations.zammad.org">
          translations.zammad.org
        </CommonLink>
      </template>
    </FormGroup>

    <CommonSectionMenu v-if="hasVersionPermission || showInstallButton">
      <CommonSectionMenuLink
        v-if="hasVersionPermission"
        :icon="{ name: 'mobile-info', size: 'base' }"
        :information="productAbout?.productAbout"
        icon-bg="bg-gray"
      >
        {{ $t('About') }}
      </CommonSectionMenuLink>
      <CommonSectionMenuLink
        v-if="showInstallButton"
        :icon="{ name: 'mobile-install', size: 'small' }"
        icon-bg="bg-blue"
        @click="installZammadPWA"
      >
        {{ $t('Install App') }}
      </CommonSectionMenuLink>
    </CommonSectionMenu>

    <div class="mb-4">
      <FormKit
        wrapper-class="mt-4 text-base flex grow justify-center items-center"
        input-class="py-2 px-4 w-full h-14 !text-red-bright formkit-variant-primary:bg-red-dark rounded-xl select-none"
        type="submit"
        name="signout"
        @click="logout"
      >
        {{ $t('Sign out') }}
      </FormKit>
    </div>

    <CommonSectionPopup v-model:state="showInstallIOSPopup" :items="[]">
      <template #header>
        <section class="inline-flex min-h-[54px] items-center p-3">
          <span v-html="installPWAMessage" />
        </section>
      </template>
    </CommonSectionPopup>
  </div>
</template>
