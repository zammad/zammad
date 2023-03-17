<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
interface Props {
  subject?: Maybe<string>
  to?: Maybe<string>
}

defineProps<Props>()
</script>

<template>
  <div class="text-center text-gray">"{{ subject }}" -&gt; "{{ to }}"</div>
</template>
