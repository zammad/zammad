import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './templates.api.ts'

export function mockTemplatesQuery(defaults: Mocks.MockDefaultsValue<Types.TemplatesQuery, Types.TemplatesQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TemplatesDocument, defaults)
}

export function waitForTemplatesQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TemplatesQuery>(Operations.TemplatesDocument)
}
