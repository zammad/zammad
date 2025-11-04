import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './organizationInfoForPopover.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockOrganizationInfoForPopoverQuery(defaults: Mocks.MockDefaultsValue<Types.OrganizationInfoForPopoverQuery, Types.OrganizationInfoForPopoverQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.OrganizationInfoForPopoverDocument, defaults)
}

export function waitForOrganizationInfoForPopoverQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.OrganizationInfoForPopoverQuery>(Operations.OrganizationInfoForPopoverDocument)
}

export function mockOrganizationInfoForPopoverQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.OrganizationInfoForPopoverDocument, message, extensions);
}
