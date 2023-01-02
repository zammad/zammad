<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'
</script>

<template>
  <Story>
    <Variant title="Default">
      <div class="relative h-[200px] bg-black text-white">
        <FormKit
          type="editor"
          label="Click text"
          name="body"
          value="<p>Hello <b>World</b>! 🎉</p>"
        />
      </div>
    </Variant>
  </Story>
</template>
