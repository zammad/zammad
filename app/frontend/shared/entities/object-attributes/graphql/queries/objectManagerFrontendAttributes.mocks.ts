import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './objectManagerFrontendAttributes.api.ts'

export function mockObjectManagerFrontendAttributesQuery(defaults: Mocks.MockDefaultsValue<Types.ObjectManagerFrontendAttributesQuery, Types.ObjectManagerFrontendAttributesQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.ObjectManagerFrontendAttributesDocument, defaults)
}

export function waitForObjectManagerFrontendAttributesQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ObjectManagerFrontendAttributesQuery>(Operations.ObjectManagerFrontendAttributesDocument)
}
