---
to: <%- h.getPath(path) %>
---
<!-- <%= h.zammadCopyright() %> -->

<script setup lang="ts"></script>

<template>
  <div>Hello <%= h.convertCase.pascal(componentName) %></div>
</template>
