<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import { useApplicationStore } from '#shared/stores/application.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import { useEmailAddressesQuery } from '#desktop/entities/email-addresses/graphql/queries/emailAddresses.api.ts'

import GuidedSetupActionFooter from '../../components/GuidedSetupActionFooter.vue'
import { useSystemSetupManual } from '../../composables/useSystemSetupManual.ts'

defineOptions({
  beforeRouteEnter() {
    const application = useApplicationStore()

    if (!application.config.system_online_service) {
      return '/guided-setup/manual/channels/email'
    }

    return true
  },
})

const router = useRouter()

const { setTitle } = useSystemSetupManual()

setTitle(__('Connect Channels'))

const emailAddressesQuery = new QueryHandler(
  useEmailAddressesQuery({
    onlyActive: true,
  }),
)
const emailAddressesResult = emailAddressesQuery.result()

const emailAddresses = computed(() => {
  return (
    emailAddressesResult.value?.emailAddresses.map((emailAddress) => {
      return {
        name: emailAddress.name,
        email: emailAddress.email,
      }
    }) || []
  )
})

const finish = () => {
  router.push('/guided-setup/manual/finish')
}
</script>

<template>
  <div class="flex flex-col gap-2.5">
    <CommonLabel>
      {{ $t('Your Zammad has the following email address:') }}
    </CommonLabel>

    <ul
      class="text-sm dark:text-neutral-400 text-gray-100 gap-1 list-disc ltr:ml-5 rtl:mr-5"
    >
      <li v-for="address in emailAddresses" :key="address.email">
        {{ address.name }} &lt;{{ address.email }}&gt;
      </li>
    </ul>

    <CommonLabel>
      {{
        $t(
          'If you want to use additional email addresses, you can configure them later.',
        )
      }}
    </CommonLabel>
    <GuidedSetupActionFooter
      go-back-route="/guided-setup/manual/system-information"
      :submit-button-text="__('Finish')"
      submit-button-type="button"
      @submit="finish"
    />
  </div>
</template>
