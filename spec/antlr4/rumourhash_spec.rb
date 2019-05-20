require 'spec_helper'

RSpec.describe RumourHash do

  it "run rumourhash" do
    hash = RumourHash.update_int(1, 2)
    expect(hash).to eq(-3876823286909082892)
  end
end

