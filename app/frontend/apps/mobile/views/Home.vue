<template>
  <div>
    <h1>Home</h1>
    <p>{{ userData?.firstname }} {{ userData?.lastname }}</p>
    <br />
    <p v-on:click="logout">Logout</p>
  </div>
</template>

<script setup lang="ts">
import useNotifications from '@common/composables/useNotifications'
import useAuthenticatedStore from '@common/stores/authenticated'
import useSessionUserStore from '@common/stores/session/user'
import { storeToRefs } from 'pinia'
import { useRouter } from 'vue-router'

// TODO ... testing the notification
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
</script>
