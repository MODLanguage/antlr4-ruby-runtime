class MurmurHash
  DEFAULT_SEED = 0

  def self.update_int(hash, value)
    c1 = 0xCC9E2D51
    c2 = 0x1B873593
    r1 = 15
    r2 = 13
    m = 5
    n = 0xE6546B64

    k = value
    k *= c1
    k = (k << r1) | (k >> (32 - r1))
    k *= c2

    hash = hash ^ k
    hash = (hash << r2) | (hash >> (32 - r2))
    hash * m + n
  end

  def self.update_obj(hash, value)
    update_int(hash, !value.nil? ? value.hash : 0)
  end

  def self.finish(hash, n_words)
    hash = hash ^ (n_words * 4)
    hash = hash ^ (hash >> 16)
    hash *= 0x85EBCA6B
    hash = hash ^ (hash >> 13)
    hash *= 0xC2B2AE35
    hash ^ (hash >> 16)
  end

  def self.hash(data, seed)
    hash = seed
    data.each do |value|
      hash = update_obj(hash, value)
    end

    finish(hash, data.length)
  end
end
