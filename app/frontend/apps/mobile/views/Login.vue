<template>
  <div>
    <h1>Login</h1>
    <p>Username: <input v-model="loginFormValues.login" type="text" /></p>
    <br />
    <p>
      Password: <input v-model="loginFormValues.password" type="password" />
    </p>
    <br />
    <button v-on:click="login">Login</button>
  </div>
</template>

<script setup lang="ts">
import useAuthenticationStore from '@common/stores/authenticated'
import { useRouter } from 'vue-router'

const authentication = useAuthenticationStore()
const loginFormValues = {
  login: '',
  password: '',
}

const router = useRouter()

const login = (): void => {
  authentication
    .login(loginFormValues.login, loginFormValues.password)
    .then(() => {
      router.replace('/')
    })
}
</script>
