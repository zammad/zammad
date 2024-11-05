---
to: "<%= withTypeFile ? h.getPath('genericComponent', {directoryScope, suffix: `${h.usePrefix(componentName, 'generic')}/__test__/${h.usePrefix(componentName, 'use')}.spec.ts`}) : null %>"
---
// <%= h.zammadCopyright() %>

import { <%= h.usePrefix(componentName, 'use') %> } from '#<%= h.componentLibrary(directoryScope, false) %>/components/<%= h.usePrefix(componentName, 'generic') %>/<%= h.usePrefix(componentName, 'use') %>.ts'

describe('<%= h.usePrefix(componentName, 'use') %>', () => {
  it.todo('test <%= h.usePrefix(componentName, 'use') %>', () => {
    const composable = <%= h.usePrefix(componentName, 'use') %>()
    expect(composable)
  })
})
