## What does this MR do?

<!--Insert the link to a GitHub issue in (), or describe the changes if there is no issue -->
[Issue Link]()

## Screenshots  <!-- Optional, very helpful for the reviewer colleagues from other teams -->

### Before

![alt text](https://example.com/before.png)

### After

![alt text](https://example.com/after.png)

## Code Changes

* This MR
  **does**  <!-- KEEP ONLY ONE -->
  does not  <!-- OF THESE LINES -->
  change more than 3 files / 100 lines of code.

  <!-- If so, what’s the connection? Or, could you split it into multiple MRs? -->

* This MR
  **does**  <!-- KEEP ONLY ONE -->
  does not  <!-- OF THESE LINES -->
  introduce new methods.

  <!-- If so, are they tested? -->

* This MR
  **does**  <!-- KEEP ONLY ONE -->
  does not  <!-- OF THESE LINES -->
  modify or remove existing methods.

  <!-- If so, did you modify/remove their tests, as well? -->

* This MR
  **does**  <!-- KEEP ONLY ONE -->
  does not  <!-- OF THESE LINES -->
  add to, modify, or remove existing test cases.

  <!-- If so, explain. -->

### Performance Impact  <!-- Optional -->

<!--
Does your MR optimize (or degrade) performance?
If so, apply the label and explain here.

Consider that some of OTRS’s customers had
HUNDREDS of agents, overviews, and groups,
over 2,000 tickets a day,
and over 20,000,000 (!) tickets in all.
How do your performance changes scale on a system of this size?

(Remember, these are not edge cases we can ignore;
they are really big customers, and we want to keep their business!)
-->

### Documentation Follow-up Required?

<!-- Keep one of the two sections -->

<!--
If this MR does change:
- How the user experiences or uses the application
  - Visual appearance
  - Screen flow
  - Texts
- How the application is deployed an maintained
  - Deployment process
  - System requirements
  - Command line interfaces
 -->
This MR may require follow-up by the documentation team.
/label ~Documentation

<!--
Otherwise
-->
This MR does not require any follow-up.

## QA Checklist (to be filled by the reviewer)

- [ ] Implementation satisfies specification
- [ ] Changes confirmed by manual testing
- [ ] [Code style](https://git.zammad.com/zammad/zammad/-/wikis/Coding-style-guide) is appropriate
- [ ] Performance will not degrade
- [ ] Code is properly covered with tests
- If follow-up by the documentation team is needed:
  - [ ] Add a comment with this text
> @<!-- don't treat this as a mention until copied -->MrGeneration please check if this MR requires changes to the documentation. Thanks!
