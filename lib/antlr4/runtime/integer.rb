class Integer
  N_BYTES = [42].pack('i').size
  N_BITS = N_BYTES * 16
  MAX = 2**(N_BITS - 2) - 1
  MIN = -MAX - 1

  def self.signum(x)
    return 0 if x.zero?
    return -1 if x < 0
    1
  end
end
