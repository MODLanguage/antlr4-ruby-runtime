require './spec/spec_helper'

RSpec.describe Antlr4::Runtime do

  it "can use bit_set correctly" do
    s = Antlr4::Runtime::BitSet.new
    t = Antlr4::Runtime::BitSet.new

    s.set(3)
    result = s.bits
    expect(result).to eq(8)
    result = s.next_set_bit(0)
    expect(result).to eq(3)

    t.set(4)
    t.set(5)
    t.set(6)
    s.or(t)
    result = s.bits
    expect(result).to eq(120)

    result = s.get(2)
    expect(result).to be(false)
    result = s.get(3)
    expect(result).to be(true)
    result = s.get(4)
    expect(result).to be(true)
    result = s.get(5)
    expect(result).to be(true)
    result = s.get(6)
    expect(result).to be(true)
    result = s.get(7)
    expect(result).to be(false)

  end
end
