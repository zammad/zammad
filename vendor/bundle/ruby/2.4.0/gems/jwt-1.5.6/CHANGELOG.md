# Change Log

## [v1.5.6](https://github.com/jwt/ruby-jwt/tree/v1.5.6) (2016-09-19)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v1.5.5...v1.5.6)

**Fixed bugs:**

- Fix missing symbol handling in aud verify code [\#166](https://github.com/jwt/ruby-jwt/pull/166) ([excpt](https://github.com/excpt))

**Merged pull requests:**

- Fix rubocop code smells [\#167](https://github.com/jwt/ruby-jwt/pull/167) ([excpt](https://github.com/excpt))

## [v1.5.5](https://github.com/jwt/ruby-jwt/tree/v1.5.5) (2016-09-16)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v1.5.4...v1.5.5)

**Implemented enhancements:**

- JWT.decode always raises JWT::ExpiredSignature for tokens created with Time objects passed as the `exp` parameter [\#148](https://github.com/jwt/ruby-jwt/issues/148)

**Fixed bugs:**

- expiration check does not give "Signature has expired" error for the exact time of expiration [\#157](https://github.com/jwt/ruby-jwt/issues/157)
- JTI claim broken? [\#152](https://github.com/jwt/ruby-jwt/issues/152)
- Audience Claim broken? [\#151](https://github.com/jwt/ruby-jwt/issues/151)
- 1.5.3 breaks compatibility with 1.5.2 [\#133](https://github.com/jwt/ruby-jwt/issues/133)
- Version 1.5.3 breaks 1.9.3 compatibility, but not documented as such [\#132](https://github.com/jwt/ruby-jwt/issues/132)
- Fix: exp claim check [\#161](https://github.com/jwt/ruby-jwt/pull/161) ([excpt](https://github.com/excpt))

**Closed issues:**

- Rendering Json Results in JWT::DecodeError [\#162](https://github.com/jwt/ruby-jwt/issues/162)
- PHP Libraries [\#154](https://github.com/jwt/ruby-jwt/issues/154)
- \[security\] Signature verified after expiration/sub/iss checks [\#153](https://github.com/jwt/ruby-jwt/issues/153)
- Is ruby-jwt thread-safe? [\#150](https://github.com/jwt/ruby-jwt/issues/150)
- JWT 1.5.3 [\#143](https://github.com/jwt/ruby-jwt/issues/143)
- gem install v 1.5.3 returns error [\#141](https://github.com/jwt/ruby-jwt/issues/141)
- Adding a CHANGELOG [\#140](https://github.com/jwt/ruby-jwt/issues/140)

**Merged pull requests:**

- Bump version [\#165](https://github.com/jwt/ruby-jwt/pull/165) ([excpt](https://github.com/excpt))
- Improve error message for exp claim in payload [\#164](https://github.com/jwt/ruby-jwt/pull/164) ([excpt](https://github.com/excpt))
- Fix \#151 and code refactoring [\#163](https://github.com/jwt/ruby-jwt/pull/163) ([excpt](https://github.com/excpt))
- Signature validation before claim verification [\#160](https://github.com/jwt/ruby-jwt/pull/160) ([excpt](https://github.com/excpt))
- Create specs for README.md examples [\#159](https://github.com/jwt/ruby-jwt/pull/159) ([excpt](https://github.com/excpt))
- Tiny Readme Improvement [\#156](https://github.com/jwt/ruby-jwt/pull/156) ([b264](https://github.com/b264))
- Added test execution to Rakefile [\#147](https://github.com/jwt/ruby-jwt/pull/147) ([jabbrwcky](https://github.com/jabbrwcky))
- Add more bling bling to the site [\#146](https://github.com/jwt/ruby-jwt/pull/146) ([excpt](https://github.com/excpt))
- Bump version [\#145](https://github.com/jwt/ruby-jwt/pull/145) ([excpt](https://github.com/excpt))
- Add first content and basic layout [\#144](https://github.com/jwt/ruby-jwt/pull/144) ([excpt](https://github.com/excpt))
- Add a changelog file [\#142](https://github.com/jwt/ruby-jwt/pull/142) ([excpt](https://github.com/excpt))
- Return decoded\_segments [\#139](https://github.com/jwt/ruby-jwt/pull/139) ([akostrikov](https://github.com/akostrikov))

## [v1.5.4](https://github.com/jwt/ruby-jwt/tree/v1.5.4) (2016-03-24)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/v1.5.3...v1.5.4)

**Closed issues:**

- 404 at https://rubygems.global.ssl.fastly.net/gems/jwt-1.5.3.gem [\#137](https://github.com/jwt/ruby-jwt/issues/137)

**Merged pull requests:**

- Update README.md [\#138](https://github.com/jwt/ruby-jwt/pull/138) ([excpt](https://github.com/excpt))
- Fix base64url\_decode [\#136](https://github.com/jwt/ruby-jwt/pull/136) ([excpt](https://github.com/excpt))
- Fix ruby 1.9.3 compatibility [\#135](https://github.com/jwt/ruby-jwt/pull/135) ([excpt](https://github.com/excpt))
- iat can be a float value [\#134](https://github.com/jwt/ruby-jwt/pull/134) ([llimllib](https://github.com/llimllib))

## [v1.5.3](https://github.com/jwt/ruby-jwt/tree/v1.5.3) (2016-02-24)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.5.2...v1.5.3)

**Implemented enhancements:**

- Refactor obsolete code for ruby 1.8 support [\#120](https://github.com/jwt/ruby-jwt/issues/120)
- Fix "Rubocop/Metrics/CyclomaticComplexity" issue in lib/jwt.rb [\#106](https://github.com/jwt/ruby-jwt/issues/106)
- Fix "Rubocop/Metrics/CyclomaticComplexity" issue in lib/jwt.rb [\#105](https://github.com/jwt/ruby-jwt/issues/105)
- Allow a proc to be passed for JTI verification [\#126](https://github.com/jwt/ruby-jwt/pull/126) ([yahooguntu](https://github.com/yahooguntu))
- Relax restrictions on "jti" claim verification [\#113](https://github.com/jwt/ruby-jwt/pull/113) ([lwe](https://github.com/lwe))

**Closed issues:**

- Verifications not functioning in latest release [\#128](https://github.com/jwt/ruby-jwt/issues/128)
- Base64 is generating invalid length base64 strings - cross language interop [\#127](https://github.com/jwt/ruby-jwt/issues/127)
- Digest::Digest is deprecated; use Digest [\#119](https://github.com/jwt/ruby-jwt/issues/119)
- verify\_rsa no method 'verify' for class String [\#115](https://github.com/jwt/ruby-jwt/issues/115)
- Add a changelog [\#111](https://github.com/jwt/ruby-jwt/issues/111)

**Merged pull requests:**

- Drop ruby 1.9.3 support [\#131](https://github.com/jwt/ruby-jwt/pull/131) ([excpt](https://github.com/excpt))
- Allow string hash keys in validation configurations [\#130](https://github.com/jwt/ruby-jwt/pull/130) ([tpickett66](https://github.com/tpickett66))
- Add ruby 2.3.0 for travis ci testing [\#123](https://github.com/jwt/ruby-jwt/pull/123) ([excpt](https://github.com/excpt))
- Remove obsolete json code [\#122](https://github.com/jwt/ruby-jwt/pull/122) ([excpt](https://github.com/excpt))
- Add fancy badges to README.md [\#118](https://github.com/jwt/ruby-jwt/pull/118) ([excpt](https://github.com/excpt))
- Refactor decode and verify functionality [\#117](https://github.com/jwt/ruby-jwt/pull/117) ([excpt](https://github.com/excpt))
- Drop echoe dependency for gem releases [\#116](https://github.com/jwt/ruby-jwt/pull/116) ([excpt](https://github.com/excpt))
- Updated readme for iss/aud options [\#114](https://github.com/jwt/ruby-jwt/pull/114) ([ryanmcilmoyl](https://github.com/ryanmcilmoyl))
- Fix error misspelling [\#112](https://github.com/jwt/ruby-jwt/pull/112) ([kat3kasper](https://github.com/kat3kasper))

## [jwt-1.5.2](https://github.com/jwt/ruby-jwt/tree/jwt-1.5.2) (2015-10-27)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.5.1...jwt-1.5.2)

**Implemented enhancements:**

- Must we specify algorithm when calling decode to avoid vulnerabilities? [\#107](https://github.com/jwt/ruby-jwt/issues/107)
- Code review: Rspec test refactoring [\#85](https://github.com/jwt/ruby-jwt/pull/85) ([excpt](https://github.com/excpt))

**Fixed bugs:**

- aud verifies if aud is passed in, :sub does not [\#102](https://github.com/jwt/ruby-jwt/issues/102)
- iat check does not use leeway so nbf could pass, but iat fail [\#83](https://github.com/jwt/ruby-jwt/issues/83)

**Closed issues:**

- Test ticket from Code Climate [\#104](https://github.com/jwt/ruby-jwt/issues/104)
- Test ticket from Code Climate [\#100](https://github.com/jwt/ruby-jwt/issues/100)
- Is it possible to decode the payload without validating the signature? [\#97](https://github.com/jwt/ruby-jwt/issues/97)
- What is audience? [\#96](https://github.com/jwt/ruby-jwt/issues/96)
- Options hash uses both symbols and strings as keys. [\#95](https://github.com/jwt/ruby-jwt/issues/95)

**Merged pull requests:**

- Fix incorrect `iat` examples [\#109](https://github.com/jwt/ruby-jwt/pull/109) ([kjwierenga](https://github.com/kjwierenga))
- Update docs to include instructions for the algorithm parameter. [\#108](https://github.com/jwt/ruby-jwt/pull/108) ([aarongray](https://github.com/aarongray))
- make sure :sub check behaves like :aud check [\#103](https://github.com/jwt/ruby-jwt/pull/103) ([skippy](https://github.com/skippy))
- Change hash syntax [\#101](https://github.com/jwt/ruby-jwt/pull/101) ([excpt](https://github.com/excpt))
- Include LICENSE and README.md in gem [\#99](https://github.com/jwt/ruby-jwt/pull/99) ([bkeepers](https://github.com/bkeepers))
- Remove unused variable in the sample code. [\#98](https://github.com/jwt/ruby-jwt/pull/98) ([hypermkt](https://github.com/hypermkt))
- Fix iat claim example [\#94](https://github.com/jwt/ruby-jwt/pull/94) ([larrylv](https://github.com/larrylv))
- Fix wrong description in README.md [\#93](https://github.com/jwt/ruby-jwt/pull/93) ([larrylv](https://github.com/larrylv))
- JWT and JWA are now RFC. [\#92](https://github.com/jwt/ruby-jwt/pull/92) ([aj-michael](https://github.com/aj-michael))
- Update README.md [\#91](https://github.com/jwt/ruby-jwt/pull/91) ([nsarno](https://github.com/nsarno))
- Fix missing verify parameter in docs [\#90](https://github.com/jwt/ruby-jwt/pull/90) ([ernie](https://github.com/ernie))
- Iat check uses leeway. [\#89](https://github.com/jwt/ruby-jwt/pull/89) ([aj-michael](https://github.com/aj-michael))
- nbf check allows exact time matches. [\#88](https://github.com/jwt/ruby-jwt/pull/88) ([aj-michael](https://github.com/aj-michael))

## [jwt-1.5.1](https://github.com/jwt/ruby-jwt/tree/jwt-1.5.1) (2015-06-22)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.5.0...jwt-1.5.1)

**Implemented enhancements:**

- Fix either README or source code [\#78](https://github.com/jwt/ruby-jwt/issues/78)
- Validate against draft 20 [\#38](https://github.com/jwt/ruby-jwt/issues/38)

**Fixed bugs:**

- ECDSA signature verification fails for valid tokens [\#84](https://github.com/jwt/ruby-jwt/issues/84)
- Shouldn't verification of additional claims, like iss, aud etc. be enforced when in options? [\#81](https://github.com/jwt/ruby-jwt/issues/81)
- Fix either README or source code [\#78](https://github.com/jwt/ruby-jwt/issues/78)
- decode fails with 'none' algorithm and verify [\#75](https://github.com/jwt/ruby-jwt/issues/75)

**Closed issues:**

- Doc mismatch: uninitialized constant JWT::ExpiredSignature [\#79](https://github.com/jwt/ruby-jwt/issues/79)
- TypeError when specifying a wrong algorithm [\#77](https://github.com/jwt/ruby-jwt/issues/77)
- jti verification doesn't prevent replays [\#73](https://github.com/jwt/ruby-jwt/issues/73)

**Merged pull requests:**

- Correctly sign ECDSA JWTs [\#87](https://github.com/jwt/ruby-jwt/pull/87) ([jurriaan](https://github.com/jurriaan))
- fixed results of decoded tokens in readme [\#86](https://github.com/jwt/ruby-jwt/pull/86) ([piscolomo](https://github.com/piscolomo))
- Force verification of "iss" and "aud" claims [\#82](https://github.com/jwt/ruby-jwt/pull/82) ([lwe](https://github.com/lwe))

## [jwt-1.5.0](https://github.com/jwt/ruby-jwt/tree/jwt-1.5.0) (2015-05-09)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.4.1...jwt-1.5.0)

**Implemented enhancements:**

- Needs to support asymmetric key signatures over shared secrets [\#46](https://github.com/jwt/ruby-jwt/issues/46)
- Implement Elliptic Curve Crypto Signatures [\#74](https://github.com/jwt/ruby-jwt/pull/74) ([jtdowney](https://github.com/jtdowney))
- Add an option to verify the signature on decode [\#71](https://github.com/jwt/ruby-jwt/pull/71) ([javawizard](https://github.com/javawizard))

**Closed issues:**

- Check JWT vulnerability [\#76](https://github.com/jwt/ruby-jwt/issues/76)

**Merged pull requests:**

- Fixed some examples to make them copy-pastable [\#72](https://github.com/jwt/ruby-jwt/pull/72) ([jer](https://github.com/jer))

## [jwt-1.4.1](https://github.com/jwt/ruby-jwt/tree/jwt-1.4.1) (2015-03-12)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.4.0...jwt-1.4.1)

**Fixed bugs:**

- jti verification not working per the spec [\#68](https://github.com/jwt/ruby-jwt/issues/68)
- Verify ISS should be off by default [\#66](https://github.com/jwt/ruby-jwt/issues/66)

**Merged pull requests:**

- Fix \#66 \#68 [\#69](https://github.com/jwt/ruby-jwt/pull/69) ([excpt](https://github.com/excpt))
- When throwing errors, mention expected/received values [\#65](https://github.com/jwt/ruby-jwt/pull/65) ([rolodato](https://github.com/rolodato))

## [jwt-1.4.0](https://github.com/jwt/ruby-jwt/tree/jwt-1.4.0) (2015-03-10)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.3.0...jwt-1.4.0)

**Closed issues:**

- The behavior using 'json' differs from 'multi\_json' [\#41](https://github.com/jwt/ruby-jwt/issues/41)

**Merged pull requests:**

- Release 1.4.0 [\#64](https://github.com/jwt/ruby-jwt/pull/64) ([excpt](https://github.com/excpt))
- Update README.md and remove dead code [\#63](https://github.com/jwt/ruby-jwt/pull/63) ([excpt](https://github.com/excpt))
- Add  'iat/ aud/ sub/ jti'  support for ruby-jwt [\#62](https://github.com/jwt/ruby-jwt/pull/62) ([ZhangHanDong](https://github.com/ZhangHanDong))
- Add  'iss'  support for ruby-jwt [\#61](https://github.com/jwt/ruby-jwt/pull/61) ([ZhangHanDong](https://github.com/ZhangHanDong))
- Clarify .encode API in README [\#60](https://github.com/jwt/ruby-jwt/pull/60) ([jbodah](https://github.com/jbodah))

## [jwt-1.3.0](https://github.com/jwt/ruby-jwt/tree/jwt-1.3.0) (2015-02-24)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.2.1...jwt-1.3.0)

**Closed issues:**

- Signature Verification to Return Verification Error rather than decode error [\#57](https://github.com/jwt/ruby-jwt/issues/57)
- Incorrect readme for leeway [\#55](https://github.com/jwt/ruby-jwt/issues/55)
- What is the reason behind stripping the = in base64 encoding? [\#54](https://github.com/jwt/ruby-jwt/issues/54)
- Preperations for version 2.x [\#50](https://github.com/jwt/ruby-jwt/issues/50)
- Release a new version [\#47](https://github.com/jwt/ruby-jwt/issues/47)
- Catch up for ActiveWhatever 4.1.1 series [\#40](https://github.com/jwt/ruby-jwt/issues/40)

**Merged pull requests:**

- raise verification error for signiture verification [\#58](https://github.com/jwt/ruby-jwt/pull/58) ([punkle](https://github.com/punkle))
- Added support for not before claim verification [\#56](https://github.com/jwt/ruby-jwt/pull/56) ([punkle](https://github.com/punkle))
- Preperations for version 2.x [\#49](https://github.com/jwt/ruby-jwt/pull/49) ([excpt](https://github.com/excpt))

## [jwt-1.2.1](https://github.com/jwt/ruby-jwt/tree/jwt-1.2.1) (2015-01-22)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.2.0...jwt-1.2.1)

**Closed issues:**

- JWT.encode\({"exp": 10}, "secret"\) [\#52](https://github.com/jwt/ruby-jwt/issues/52)
- JWT.encode\({"exp": 10}, "secret"\) [\#51](https://github.com/jwt/ruby-jwt/issues/51)

**Merged pull requests:**

- Accept expiration claims as string [\#53](https://github.com/jwt/ruby-jwt/pull/53) ([yarmand](https://github.com/yarmand))

## [jwt-1.2.0](https://github.com/jwt/ruby-jwt/tree/jwt-1.2.0) (2014-11-24)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.13...jwt-1.2.0)

**Closed issues:**

- set token to expire [\#42](https://github.com/jwt/ruby-jwt/issues/42)

**Merged pull requests:**

- Added support for `exp` claim [\#45](https://github.com/jwt/ruby-jwt/pull/45) ([zshannon](https://github.com/zshannon))
- rspec 3 breaks passing tests [\#44](https://github.com/jwt/ruby-jwt/pull/44) ([zshannon](https://github.com/zshannon))

## [jwt-0.1.13](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.13) (2014-05-08)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-1.0.0...jwt-0.1.13)

**Closed issues:**

- yanking of version 0.1.12 causes issues [\#39](https://github.com/jwt/ruby-jwt/issues/39)
- Semantic versioning [\#37](https://github.com/jwt/ruby-jwt/issues/37)
- Update gem to get latest changes [\#36](https://github.com/jwt/ruby-jwt/issues/36)

## [jwt-1.0.0](https://github.com/jwt/ruby-jwt/tree/jwt-1.0.0) (2014-05-07)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.11...jwt-1.0.0)

**Closed issues:**

- API request - JWT::decoded\_header\(\) [\#26](https://github.com/jwt/ruby-jwt/issues/26)

**Merged pull requests:**

- return header along with playload after decoding [\#35](https://github.com/jwt/ruby-jwt/pull/35) ([sawyerzhang](https://github.com/sawyerzhang))
- Raise JWT::DecodeError on nil token [\#34](https://github.com/jwt/ruby-jwt/pull/34) ([tjmw](https://github.com/tjmw))
- Make MultiJson optional for Ruby 1.9+ [\#33](https://github.com/jwt/ruby-jwt/pull/33) ([petergoldstein](https://github.com/petergoldstein))
- Allow access to header and payload without signature verification [\#32](https://github.com/jwt/ruby-jwt/pull/32) ([petergoldstein](https://github.com/petergoldstein))
- Update specs to use RSpec 3.0.x syntax [\#31](https://github.com/jwt/ruby-jwt/pull/31) ([petergoldstein](https://github.com/petergoldstein))
- Travis - Add Ruby 2.0.0, 2.1.0, Rubinius [\#30](https://github.com/jwt/ruby-jwt/pull/30) ([petergoldstein](https://github.com/petergoldstein))

## [jwt-0.1.11](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.11) (2014-01-17)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.10...jwt-0.1.11)

**Closed issues:**

- url safe encode and decode [\#28](https://github.com/jwt/ruby-jwt/issues/28)
- Release [\#27](https://github.com/jwt/ruby-jwt/issues/27)

**Merged pull requests:**

- fixed urlsafe base64 encoding [\#29](https://github.com/jwt/ruby-jwt/pull/29) ([tobscher](https://github.com/tobscher))

## [jwt-0.1.10](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.10) (2014-01-10)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.8...jwt-0.1.10)

**Closed issues:**

- change to signature of JWT.decode method [\#14](https://github.com/jwt/ruby-jwt/issues/14)

**Merged pull requests:**

- Fix warning: assigned but unused variable - e [\#25](https://github.com/jwt/ruby-jwt/pull/25) ([sferik](https://github.com/sferik))
- Echoe doesn't define a license= method [\#24](https://github.com/jwt/ruby-jwt/pull/24) ([sferik](https://github.com/sferik))
- Use OpenSSL::Digest instead of deprecated OpenSSL::Digest::Digest [\#23](https://github.com/jwt/ruby-jwt/pull/23) ([JuanitoFatas](https://github.com/JuanitoFatas))
- Handle some invalid JWTs [\#22](https://github.com/jwt/ruby-jwt/pull/22) ([steved](https://github.com/steved))
- Add MIT license to gemspec [\#21](https://github.com/jwt/ruby-jwt/pull/21) ([nycvotes-dev](https://github.com/nycvotes-dev))
- Tweaks and improvements [\#20](https://github.com/jwt/ruby-jwt/pull/20) ([threedaymonk](https://github.com/threedaymonk))
- Don't leave errors in OpenSSL.errors when there is a decoding error. [\#19](https://github.com/jwt/ruby-jwt/pull/19) ([lowellk](https://github.com/lowellk))

## [jwt-0.1.8](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.8) (2013-03-14)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.7...jwt-0.1.8)

**Merged pull requests:**

- Contrib and update [\#18](https://github.com/jwt/ruby-jwt/pull/18) ([threedaymonk](https://github.com/threedaymonk))
- Verify if verify is truthy \(not just true\) [\#17](https://github.com/jwt/ruby-jwt/pull/17) ([threedaymonk](https://github.com/threedaymonk))

## [jwt-0.1.7](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.7) (2013-03-07)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.6...jwt-0.1.7)

**Merged pull requests:**

- Catch MultiJson::LoadError and reraise as JWT::DecodeError [\#16](https://github.com/jwt/ruby-jwt/pull/16) ([rwygand](https://github.com/rwygand))

## [jwt-0.1.6](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.6) (2013-03-05)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.5...jwt-0.1.6)

**Merged pull requests:**

- Fixes a theoretical timing attack [\#15](https://github.com/jwt/ruby-jwt/pull/15) ([mgates](https://github.com/mgates))
- Use StandardError as parent for DecodeError [\#13](https://github.com/jwt/ruby-jwt/pull/13) ([Oscil8](https://github.com/Oscil8))

## [jwt-0.1.5](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.5) (2012-07-20)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.4...jwt-0.1.5)

**Closed issues:**

- Unable to specify signature header fields [\#7](https://github.com/jwt/ruby-jwt/issues/7)

**Merged pull requests:**

- MultiJson dependency uses ~\> but should be \>= [\#12](https://github.com/jwt/ruby-jwt/pull/12) ([sporkmonger](https://github.com/sporkmonger))
- Oops. :-\) [\#11](https://github.com/jwt/ruby-jwt/pull/11) ([sporkmonger](https://github.com/sporkmonger))
- Fix issue with signature verification in JRuby [\#10](https://github.com/jwt/ruby-jwt/pull/10) ([sporkmonger](https://github.com/sporkmonger))
- Depend on MultiJson [\#9](https://github.com/jwt/ruby-jwt/pull/9) ([lautis](https://github.com/lautis))
- Allow for custom headers on encode and decode [\#8](https://github.com/jwt/ruby-jwt/pull/8) ([dgrijalva](https://github.com/dgrijalva))
- Missing development dependency for echoe gem. [\#6](https://github.com/jwt/ruby-jwt/pull/6) ([sporkmonger](https://github.com/sporkmonger))

## [jwt-0.1.4](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.4) (2011-11-11)
[Full Changelog](https://github.com/jwt/ruby-jwt/compare/jwt-0.1.3...jwt-0.1.4)

**Merged pull requests:**

- Fix for RSA verification [\#5](https://github.com/jwt/ruby-jwt/pull/5) ([jordan-brough](https://github.com/jordan-brough))

## [jwt-0.1.3](https://github.com/jwt/ruby-jwt/tree/jwt-0.1.3) (2011-06-30)
**Closed issues:**

- signatures calculated incorrectly \(hexdigest instead of digest\) [\#1](https://github.com/jwt/ruby-jwt/issues/1)

**Merged pull requests:**

- Bumped a version and added a .gemspec using rake build\_gemspec [\#3](https://github.com/jwt/ruby-jwt/pull/3) ([zhitomirskiyi](https://github.com/zhitomirskiyi))
- Added RSA support [\#2](https://github.com/jwt/ruby-jwt/pull/2) ([zhitomirskiyi](https://github.com/zhitomirskiyi))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*