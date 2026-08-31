import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesSnipeitAssetAdd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketExternalReferencesSnipeitAssetAddMutation(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesSnipeitAssetAddMutation, Types.TicketExternalReferencesSnipeitAssetAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesSnipeitAssetAddDocument, defaults)
}

export function waitForTicketExternalReferencesSnipeitAssetAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesSnipeitAssetAddMutation>(Operations.TicketExternalReferencesSnipeitAssetAddDocument)
}

export function mockTicketExternalReferencesSnipeitAssetAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketExternalReferencesSnipeitAssetAddDocument, message, extensions);
}
