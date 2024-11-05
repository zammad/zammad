---
to: "<%= h.getPath('composable', {directoryScope: directoryScope, suffix: `__tests__/${h.usePrefix(composableName, 'use')}.spec.ts`}) %>"
---
// <%= h.zammadCopyright() %>

import { <%= h.usePrefix(composableName, 'use') %> } from '#<%= h.componentLibrary(directoryScope, false) %>/composables/<%= h.usePrefix(composableName, 'use') %>.ts'

describe('<%= h.usePrefix(composableName, 'use') %>', () => {
  it.todo('test <%= h.usePrefix(composableName, 'use') %>', () => {
    const composable = <%= h.usePrefix(composableName, 'use') %>()
    expect(composable)
  })
})
