<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { storeToRefs } from 'pinia'
import { MutationHandler } from '@shared/server/apollo/handler'
import { useSessionStore } from '@shared/stores/session'
import useLocaleStore from '@shared/stores/locale'
import FormGroup from '@shared/components/Form/FormGroup.vue'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuLink from '@mobile/components/CommonSectionMenu/CommonSectionMenuLink.vue'
import { useAccountLocaleMutation } from '../graphql/mutations/locale.api'

const router = useRouter()

const logout = () => {
  router.push('/logout')
}

const { user } = storeToRefs(useSessionStore())

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
    <CommonSectionMenu>
      <CommonSectionMenuLink
        :icon="{ name: 'user', size: 'base' }"
        icon-bg="bg-pink"
        link="/account/avatar"
      >
        {{ $t('Avatar') }}
      </CommonSectionMenuLink>
    </CommonSectionMenu>

    <!--
      TODO: no-options-label-translation is not working currently, therefore we need to explicitly set it to true
    -->
    <FormGroup>
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

    <CommonSectionMenu>
      <CommonSectionMenuLink
        :icon="{ name: 'info', size: 'base' }"
        icon-bg="bg-gray"
        information="v 1.1"
      >
        {{ $t('About') }}
      </CommonSectionMenuLink>
    </CommonSectionMenu>

    <div class="mb-4">
      <FormKit
        wrapper-class="mt-4 text-base flex grow justify-center items-center"
        input-class="py-2 px-4 w-full h-14 text-red formkit-variant-primary:bg-gray-500 rounded-xl select-none"
        type="submit"
        name="signout"
        @click="logout"
      >
        {{ $t('Sign out') }}
      </FormKit>
    </div>
  </div>
</template>
