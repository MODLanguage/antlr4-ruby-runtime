require 'spec_helper'

RSpec.describe RumourHash do

  it "run bit_count" do
    c = RumourHash.bit_count(1)
    expect(c).to eq(1)

    c = RumourHash.bit_count(3)
    expect(c).to eq(2)

    c = RumourHash.bit_count(0xFFFF)
    expect(c).to eq(16)

  end
end


