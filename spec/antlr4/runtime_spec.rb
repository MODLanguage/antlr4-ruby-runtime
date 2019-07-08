require './spec/spec_helper'

RSpec.describe Antlr4::Runtime do
  it "has a version number" do
    expect(Antlr4::Runtime::VERSION).not_to be nil
  end
end
