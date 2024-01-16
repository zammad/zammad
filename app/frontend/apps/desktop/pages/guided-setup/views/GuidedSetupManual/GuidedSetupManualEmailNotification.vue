<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { shallowRef } from 'vue'
import GuidedSetupActionFooter from '../../components/GuidedSetupActionFooter.vue'
import { useSystemSetupManual } from '../../composables/useSystemSetupManual.ts'

const { setTitle } = useSystemSetupManual()
const form = shallowRef()

setTitle(__('Email Notification'))
</script>

<template>
  <div>TODO</div>
  <GuidedSetupActionFooter
    :form="form"
    :submit-button-text="__('Save and Continue')"
  />
</template>
