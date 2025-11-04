---
to: "<%= h.getPath('store', { directoryScope: directoryScope, suffix:`${storeName}.ts`}) %>"
---
// <%= h.zammadCopyright() %>

import { acceptHMRUpdate, defineStore } from 'pinia'

export const <%= h.usePrefix(storeName) %> = defineStore('<%= storeName %>', () => {
  return {}
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(<%= h.usePrefix(storeName) %>, import.meta.hot))
}
