<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <!-- TODO: use tw styles, don't rely on "style" block! -->
  <div class="navigation flex flex-col h-full">
    <div class="text-lg h-10">Zammad</div>
    <nav class="links h-full">
      <ol>
        <li>Link 1</li>
        <li>Link 2</li>
        <li>Link 3</li>
      </ol>
    </nav>
    <RouterLink class="btn btn-error" to="/logout">Logout</RouterLink>
  </div>
</template>

<style scoped>
.navigation {
  background-color: hsl(230, 7%, 13%);
  color: white;
}

.links {
  background-color: hsl(230, 7%, 17%);
}
</style>
