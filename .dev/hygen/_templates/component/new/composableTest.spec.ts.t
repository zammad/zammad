---
to: "../../<%= withTypeFile ? `app/frontend/${h.componentLibrary(libraryName, h)}/components/${h.componentGenericWitPrefix(name, h)}/__tests__/${h.composableName(h.componentGenericWitPrefix(name, h), h)}.spec.ts` : null %>"
---
// <%= h.zammadCopyright() %>

import { renderComponent } from '#tests/support/components/index.ts'
import { <%= h.composableName(h.componentGenericWitPrefix(name, h), h) %> } from '#<%= h.componentLibrary(libraryName, false) %>/components/<%= h.componentGenericWitPrefix(name, h) %>/<%= h.composableName(h.componentGenericWitPrefix(name, h), h) %>.ts'

describe('<%= h.composableName(h.componentGenericWitPrefix(name, h), h) %>', () => {
  it('test <%= h.composableName(h.componentGenericWitPrefix(name, h), h) %>', () => {
    const composable = <%= h.composableName(h.componentGenericWitPrefix(name, h), h) %>()
    expect(composable).toHaveBeenCalledOnce()
  })
})
