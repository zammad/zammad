---
to: "<%= h.getPath('genericComponent', {directoryScope: directoryScope, suffix: h.usePrefix(componentName, 'generic') + '/__test__/' + h.usePrefix(componentName, 'generic') + '.spec.ts'}) %>"
---
// <%= h.zammadCopyright() %>

import { renderComponent } from '#tests/support/components/index.ts'

import <%= h.usePrefix(componentName, 'generic') %> from '#<%= h.componentLibrary(directoryScope, false) %>/components/<%= h.usePrefix(componentName, 'generic') %>/<%= h.usePrefix(componentName, 'generic') %>.vue'

describe('<%= h.usePrefix(componentName, 'generic') %>', () => {
  it.todo('renders <%= h.usePrefix(componentName, 'generic') %>', () => {
    renderComponent(<%= h.usePrefix(componentName, 'generic') %>, {})
  })
})
