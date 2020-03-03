
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "antlr4/runtime/version"

Gem::Specification.new do |spec|
  spec.name          = "antlr4-runtime"
  spec.version       = Antlr4::Runtime::VERSION
  spec.authors       = ["Tony Walmsley"]
  spec.email         = ["tony@aosd.co.uk"]

  spec.summary       = %q{ANTLR4 Runtime for Ruby language target lexers and parsers.}
  spec.description   = %q{This gem implements a runtime for ANTLR4 in Ruby for lexers and parsers generated using the Ruby language target.}
  spec.homepage      = "https://github.com/MODLanguage/antlr4-ruby-runtime"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib", "ext"]

  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.16.1"
  spec.extensions = %w[ext/rumourhash/extconf.rb]
end
