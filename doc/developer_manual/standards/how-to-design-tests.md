# How To Design Tests

Testing is a complex topic. In this document, we want to
provide a few tips for writing helpful tests that focus on the important.

Note that these tips don't represent the current state of testing in Zammad,
but where we want to go.

## 1. Test on the Lowest Level

Of the various testing levels (unit/functional tests, request tests, integration/end-to-end tests),
choose the lowest level that a certain functionality/piece of code can be tested on.
Stuff that is covered by a low level test does not need to be duplicated on a higher level.

## 2. Focus on the Object Under Test

Except for end-to-end and integration tests, tests should focus on the piece of code (method, object)
that is currently being tested (a.k.a. "object under test"). Other methods, objects or APIs which are used
by it can and should be mocked, where that makes sense.
Since these should have their own tests for public methods/interfaces, we don't need to cover them again in
tests of other code parts.

## 3. Test User Stories

Only certain important user stories need to be covered in high-level end-to-end (browser-based, Selenium) tests.
This should be done to ensure that the full stack is working correctly and provides the desired user experience.
