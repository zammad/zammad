---
to: ../../app/frontend/<%= h.componentLibrary(libraryName) %>/components/<%= h.componentGenericWitPrefix(name, h) %>/__tests__/<%= h.componentGenericWitPrefix(name, h) %>.spec.ts
---
// <%= h.zammadCopyright() %>

import { renderComponent } from '#tests/support/components/index.ts'
import <%= h.componentGenericWitPrefix(name, h) %> from '#<%= h.componentLibrary(libraryName, false) %>/components/<%= h.componentGenericWitPrefix(name, h) %>/<%= h.componentGenericWitPrefix(name, h) %>.vue'

describe('<%= h.componentGenericWitPrefix(name, h) %>', () => {
  it('renders <%= h.componentGenericWitPrefix(name, h) %>', () => {
    const wrapper = renderComponent(<%= h.componentGenericWitPrefix(name, h) %>, {})
    expect(wrapper).toBeInTheDocument()
  })
})
