require 'rumourhash/rumourhash'

include RumourHash

RSpec.describe RumourHash do

  it "run rumourhash" do
    hash = rumour_hash_update_int(1, 2)
    puts hash
  end
end

