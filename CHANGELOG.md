0.2.2
===
- Added a unit test for IntervalSet, fixed some bugs, removed some unused code, renamed `or_sets` to `or`.

0.2.1
===
- Call IntervalSet#or_sets (instead of #or or ||) to better match the Java version.

0.2.0
===
- A few small fixes:
  * Fixed a misspelled attr_reader in LexerCustomAction.
  * Fixed a reference to IntervalSet#or, which doesn't exist.
  * A few requires were missing. Decided to move all requires to autoloads.
  * Added require 'spec_helper' to all spec files.
  * Removed bundler as a dev dependency.
  * Added LexerATNConfig.create_from_config and LexerATNConfig.create_from_config2.
  * Fixed instance variable reference in LexerATNSimulator.
  * Removed Gemfile.lock from source control.

0.1.0
===
- Initial release
