---
to: "<%= h.getPath('genericComponent', {directoryScope: directoryScope, suffix: `${h.usePrefix(componentName, 'generic')}/${h.usePrefix(componentName, 'generic')}.vue`}) %>"
---
<!-- <%= h.zammadCopyright() %> -->

<script setup lang="ts">
interface Props {
  name: string
}

defineProps<Props>()
</script>

<template>
  <div>Hello <%= h.usePrefix(componentName, 'generic') %></div>
</template>
