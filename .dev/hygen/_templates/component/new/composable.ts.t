---
to: "../../<%= withComposable ? `app/frontend/${h.componentLibrary(libraryName, h)}/components/${h.componentGenericWitPrefix(name, h)}/${h.composableName(h.componentGenericWitPrefix(name, h), h)}.ts` : null %>"
---
// <%= h.zammadCopyright() %>

export const <%= h.composableName(h.componentGenericWitPrefix(name, h), h) %> = () => {}
