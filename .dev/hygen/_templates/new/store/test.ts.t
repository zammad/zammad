---
to: "<%= h.getPath('store', { directoryScope: directoryScope ,suffix:`__tests__/${storeName}.spec.ts`})%>"
---
// <%= h.zammadCopyright() %>

import { createPinia, setActivePinia, storeToRefs } from 'pinia'

describe('<%= h.usePrefix(storeName) %>', () => {
  beforeEach(()=> {
    setActivePinia(createPinia())
  })

  it.todo('should be tested', ()=> {
    const store = <%= h.usePrefix(storeName) %>()
    expect(store).toBeDefined()
  })
})
