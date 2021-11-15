<!-- Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div>
    <h1>Home</h1>
    <p>{{ userData?.firstname }} {{ userData?.lastname }}</p>
    <br />
    <p v-on:click="logout">Logout</p>
    <br />
    <p v-on:click="refetchConfig">refetchConfig</p>
  </div>
</template>

<script setup lang="ts">
import useNotifications from '@common/composables/useNotifications'
import useAuthenticatedStore from '@common/stores/authenticated'
import useSessionUserStore from '@common/stores/session/user'
import { storeToRefs } from 'pinia'
import { useRouter } from 'vue-router'
import useApplicationConfigStore from '@common/stores/application/config'

// TODO ... only testing the notifications.
const { notify } = useNotifications()

notify({
  message: 'Hello Home!!!',
  type: 'alert',
})

const sessionUser = useSessionUserStore()

const { value: userData } = storeToRefs(sessionUser)

const authenticated = useAuthenticatedStore()

const router = useRouter()

const logout = (): void => {
  authenticated.logout().then(() => {
    router.push('/login')
  })
}

const refetchConfig = async (): Promise<void> => {
  await useApplicationConfigStore().getConfig(true)
}
</script>
