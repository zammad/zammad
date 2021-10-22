## What does this MR do?

<!--Insert the link to a Asana card in (), or describe the task/changec if there is no related task (but normally there should be always a referenced task) -->
[Asana Task Link]()

## ToDo Checklist

- [ ] Checked that the needed functionality is not already available in a common component.
- [ ] Checked if newly created components can be added in a common way (e.g. common component).
  - [ ] Created or changed story for common component.
  - [ ] Covered common component with Jest-Test
  - [ ] Checked that i didn't add a API request inside of a common component.
- [ ] Covered new functionality with Jest-Test(*)
- [ ] When relevant: Covered new GraphQL (Mutation/Query) with a request test.

(*) Jest tests are normally only needed for the common components or other typescript functionality, because the other functionality will be tested with selenium tests and own GraphQL-API tests (with this we avoid that we need always to mock the graphql calls). But for sure special frontend handling should also be tested with a jest test.

## QA Checklist (to be filled by the reviewer)

- [ ] Implementation satisfies specification
- [ ] Changes confirmed by manual testing
- [ ] [Code style](https://git.znuny.com/zammad/zammad/-/wikis/Coding-style-guide) is appropriate
- [ ] Code is properly covered with tests
