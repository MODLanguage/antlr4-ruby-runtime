require 'antlr4/runtime/uuid'

RSpec.describe Antlr4::Runtime do

  it "can create UUIDs from strings" do
    u1 = Antlr4::Runtime::UUID.from_string('59627784-3BE5-417A-B9EB-8131A7286089')
    u2 = Antlr4::Runtime::UUID.from_string('59627784-3BE5-417A-B9EB-8131A7286089')
    expect(u1).to eq(u2)
  end
end

