require './spec/spec_helper'

RSpec.describe Antlr4::Runtime do

  it "can create Lexer" do
    lexer = Antlr4::Runtime::Lexer.new(Antlr4::Runtime::CharStreams.from_string("a=1", 'Test String'))

    expect(lexer).not_to be nil
  end
end
