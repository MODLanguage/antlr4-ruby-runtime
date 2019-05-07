require 'spec_helper'
require 'rumourhash/rumourhash'

include RumourHash

RSpec.describe RumourHash do

  it "run bit_count" do
    c = bit_count(1)
    expect(c).to eq(1)

    c = bit_count(3)
    expect(c).to eq(2)

    c = bit_count(0xFFFF)
    expect(c).to eq(16)

  end
end


