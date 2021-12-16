<!-- Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div>
    <h1>{{ i18n.t('Home') }}</h1>
    <p>{{ userData?.firstname }} {{ userData?.lastname }}</p>
    <br />
    <p v-on:click="logout">{{ i18n.t('Logout') }}</p>
    <br />
    <p v-on:click="goToTickets">Go to Tickets</p>
    <br />
    <p v-on:click="refetchConfig">refetchConfig</p>
    <br />
    <p v-on:click="fetchCurrentUser">fetchCurrentUser</p>
    <br /><br />
    <h1 class="text-lg mb-4">Configs:</h1>
    <template v-if="config.value">
      <p v-for="(value, key) in config.value" v-bind:key="(key as string)">
        Key: {{ key }}<br />
        Value: {{ value }} <br /><br />
      </p>
    </template>
  </div>
</template>

<script setup lang="ts">
import useNotifications from '@common/composables/useNotifications'
import useAuthenticatedStore from '@common/stores/authenticated'
import useSessionUserStore from '@common/stores/session/user'
import { storeToRefs } from 'pinia'
import { useRouter } from 'vue-router'
import useApplicationConfigStore from '@common/stores/application/config'
import { useCurrentUserQuery } from '@common/graphql/api'

// TODO: Only testing for the notifications...
const { notify } = useNotifications()

notify({
  message: __('Hello Home!!!'),
  type: 'alert',
})

const sessionUser = useSessionUserStore()

const { value: userData } = storeToRefs(sessionUser)

const authenticated = useAuthenticatedStore()

const router = useRouter()

const logout = (): void => {
  authenticated.logout().then(() => {
    router.push('login')
  })
}

const config = useApplicationConfigStore()

const refetchConfig = async (): Promise<void> => {
  await config.getConfig()
}

const fetchCurrentUser = () => {
  const { result } = useCurrentUserQuery({ fetchPolicy: 'no-cache' })
  console.log('result', result)
}

const goToTickets = () => {
  router.push('/tickets')
}
</script>
