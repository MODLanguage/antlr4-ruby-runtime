class DoubleKeyMap
  def initialize
    @data = {}
  end

  def put(k1, k2, v)
    data2 = @data[k1]
    prev = nil
    if data2.nil?
      data2 = {}
      @data[k1] = data2
    else
      prev = data2[k2]
    end
    data2[k2] = v
    prev
  end

  def get2(k1, k2)
    data2 = @data[k1]
    return nil if data2.nil?

    data2[k2]
  end

  def get1(k1)
    @data.get(k1)
  end

  def values(k1)
    data2 = @data.get(k1)
    return nil if data2.nil?

    data2.values
  end

  def key_set0
    @data.keySet
  end

  def key_set1(k1)
    data2 = @data[k1]
    return nil if data2.nil?

    data2.keySet
  end
end
