<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'
</script>

<template>
  <div class="space-y-2 p-4 flex flex-wrap text-xs">
    Filler text above
    <button
      class="w-full px-4 py-2.5 bg-green-200 dark:bg-gray-600 text-gray-300 dark:text-neutral-400 text-base rounded-xl inline-flex justify-center items-center gap-1.5"
    >
      <CommonIcon name="key" size="small" />
      Security Keys
    </button>
    <button
      class="w-full px-4 py-2.5 bg-blue-800 text-white text-base rounded-xl inline-flex justify-center items-center gap-1.5"
    >
      <CommonIcon name="phone" size="small" />
      Authenticator App
    </button>
    <button class="btn btn-primary btn-block">
      <CommonIcon name="phone" size="small" />
      Authenticator App
    </button>
  </div>

  <div class="w-1/2 ltr:ml-2 rtl:mr-2">
    <h1>Alerts</h1>

    <CommonAlert
      variant="info"
      dismissible
      link="https://youtu.be/U6n2NcJ7rLc"
      link-text="Party 🎉"
      class="mb-2.5"
      >It's Friday!</CommonAlert
    >
    <CommonAlert variant="success" class="mb-2.5"
      >Hooray! Ticket got updated.</CommonAlert
    >
    <CommonAlert variant="warning" class="mb-2.5"
      >Heee! You're typing too fast.</CommonAlert
    >
    <CommonAlert variant="danger" class="mb-2.5"
      >Ooops! You broke it.</CommonAlert
    >
  </div>

  <div class="ltr:ml-2 rtl:mr-2">
    <h1>Labels</h1>
    <CommonLabel size="small" prefix-icon="logo" suffix-icon="logo-flat"
      >Small</CommonLabel
    >

    <br />

    <CommonLabel size="medium" prefix-icon="logo" suffix-icon="logo-flat"
      >Medium</CommonLabel
    >

    <br />

    <CommonLabel size="large" prefix-icon="logo" suffix-icon="logo-flat"
      >Large</CommonLabel
    >

    <br />

    <CommonLabel size="xl" prefix-icon="logo" suffix-icon="logo-flat"
      >Extra large</CommonLabel
    >
  </div>
</template>
