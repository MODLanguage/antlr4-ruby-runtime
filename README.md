# Antlr4::Runtime

This gem adds support for the ANTLR4 runtime for Ruby lexers and parsers generated from the Ruby langauge 
target available at https://github.com/twalmsley/antlr4/tree/ruby_dev
## Installation

Add this line to your application's Gemfile:

```ruby
gem 'antlr4-runtime'
```

And then execute:

    $ bundle install

Or clone the repository and build and install it yourself as:

    $ rake install
    
    or if that fails:
    
    $ sudo rake install

## Usage

```ruby
require 'modl/parser/MODLParserListener'
require 'modl/parser/MODLParserVisitor'
require 'modl/parser/MODLLexer'
require 'modl/parser/MODLParser'
require 'modl/parser/Parser'
require 'modl/parser/class_processor'
require 'json'

module Modl::Parser
  class Interpreter
    def self.interpret(str)
      parsed = Modl::Parser::Parser.parse str
      interpreted = parsed.extract_json
      ClassProcessor.instance.process(parsed.global, interpreted)
      return interpreted if interpreted.is_a? String
      JSON.generate interpreted
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/MODLanguage/antlr4-ruby-runtime. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Antlr4::Runtime project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/antlr4-runtime/blob/master/CODE_OF_CONDUCT.md).
