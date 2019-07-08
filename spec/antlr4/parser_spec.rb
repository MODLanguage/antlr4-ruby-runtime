require './spec/spec_helper'

RSpec.describe Antlr4::Runtime do

  it "can create Parser" do
    lexer = Antlr4::Runtime::Lexer.new(Antlr4::Runtime::CharStreams.from_string("a=1", 'Test String'))
    tokens = Antlr4::Runtime::CommonTokenStream.new(lexer)

    parser = Antlr4::Runtime::Parser.new(tokens)

    expect(parser).not_to be nil
  end
end
