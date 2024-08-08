import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './checklistTemplates.api.ts'

export function mockChecklistTemplatesQuery(defaults: Mocks.MockDefaultsValue<Types.ChecklistTemplatesQuery, Types.ChecklistTemplatesQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChecklistTemplatesDocument, defaults)
}

export function waitForChecklistTemplatesQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChecklistTemplatesQuery>(Operations.ChecklistTemplatesDocument)
}
