<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { defineComponent, h } from 'vue'
import { useDialog } from '@shared/composables/useDialog'
import CommonDialog from './CommonDialog.vue'

const DialogDefault = defineComponent({
  setup() {
    const dialog = useDialog({
      name: 'story',
      component: async () => CommonDialog,
    })

    const openDialog = () => {
      dialog.open({
        name: 'story',
        label: 'Label',
        content: 'Content',
      })
    }
    return () =>
      h(
        'button',
        {
          onClick: openDialog,
        },
        'Toggle Dialog',
      )
  },
})
</script>

<template>
  <Story>
    <Variant title="Default">
      <DialogDefault />
    </Variant>
  </Story>
</template>
