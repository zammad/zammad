import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './systemSetupRunAutoWizard.api.ts'

export function mockSystemSetupRunAutoWizardMutation(defaults: Mocks.MockDefaultsValue<Types.SystemSetupRunAutoWizardMutation, Types.SystemSetupRunAutoWizardMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.SystemSetupRunAutoWizardDocument, defaults)
}

export function waitForSystemSetupRunAutoWizardMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.SystemSetupRunAutoWizardMutation>(Operations.SystemSetupRunAutoWizardDocument)
}
