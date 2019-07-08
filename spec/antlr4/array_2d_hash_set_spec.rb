require './spec/spec_helper'

RSpec.describe Antlr4::Runtime do

  it "can create an Array2DHashSet" do
    s = Antlr4::Runtime::Array2DHashSet.new(nil, 2, 2)

    s.add('TEST1')
    s.add('TEST2')
    s.add('TEST3')
    s.add('TEST4')
    s.add('TEST5')
    s.add('TEST6')
    s.add('TEST7')
    s.add('TEST8')
    s.add('TEST9')
    s.add('TEST10')
    s.add('TEST11')

    result = s.get('TEST1')
    expect(result).to eq('TEST1')
    result = s.get('TEST5')
    expect(result).to eq('TEST5')
    result = s.get('TEST9')
    expect(result).to eq('TEST9')
    result = s.get('TEST11')
    expect(result).to eq('TEST11')
  end

  it "can expand an Array2DHashSet" do
    s = Antlr4::Runtime::Array2DHashSet.new(nil, 2, 2)

    i = 0
    while i < 100
      s.add('TEST_' + i.to_s)
      i += 1
    end

    expect(s.size).to eq(100)
  end

  it "can compare Array2DHashSets" do
    s1 = Antlr4::Runtime::Array2DHashSet.new(nil, 2, 2)
    s2 = Antlr4::Runtime::Array2DHashSet.new(nil, 2, 2)

    i = 0
    while i < 10
      s1.add('TEST_' + i.to_s)
      s2.add('TEST_' + i.to_s)
      i += 1
    end

    expect(s1 == s1).to be(true)
    expect(s1 == s2).to be(true)
  end

  it "can iterate a Array2DHashSets" do
    s1 = Antlr4::Runtime::Array2DHashSet.new(nil, 2, 2)

    i = 0
    while i < 10
      s1.add('TEST_' + i.to_s)
      i += 1
    end

    result = []
    i = s1.iterator
    while i.has_next
      result << i.next
    end

    expect(result).to eq(%w(TEST_0 TEST_1 TEST_2 TEST_3 TEST_4 TEST_5 TEST_6 TEST_7 TEST_8 TEST_9))
  end

  it "can remove an element from an Array2DHashSet" do
    s1 = Antlr4::Runtime::Array2DHashSet.new(nil, 2, 2)

    i = 0
    while i < 10
      s1.add('TEST_' + i.to_s)
      i += 1
    end

    s1.remove(s1.get('TEST_1'))

    result = []
    i = s1.iterator
    while i.has_next
      result << i.next
    end

    expect(result).to eq(["TEST_0", "TEST_2", "TEST_3", "TEST_4", "TEST_5", "TEST_6", "TEST_7", "TEST_8", "TEST_9"])
  end

  it "can add a list of items to an Array2DHashSet" do
    s1 = Antlr4::Runtime::Array2DHashSet.new(nil, 2, 2)

    i = 0
    while i < 5
      s1.add('TEST_' + i.to_s)
      i += 1
    end

    s1.add_all(["TEST_5", "TEST_6", "TEST_7", "TEST_8", "TEST_9"])

    result = []
    i = s1.iterator
    while i.has_next
      result << i.next
    end

    expect(result).to eq(["TEST_0", "TEST_1", "TEST_2", "TEST_3", "TEST_4", "TEST_5", "TEST_6", "TEST_7", "TEST_8", "TEST_9"])
  end

  it "can retain a list of items to an Array2DHashSet" do
    s1 = Antlr4::Runtime::Array2DHashSet.new(nil, 2, 2)

    i = 0
    while i < 10
      s1.add('TEST_' + i.to_s)
      i += 1
    end

    s1.retain_all(["TEST_5", "TEST_6", "TEST_7", "TEST_8", "TEST_9", "TEST_10"])

    result = []
    i = s1.iterator
    while i.has_next
      result << i.next
    end

    expect(result).to eq(["TEST_5", "TEST_6", "TEST_7", "TEST_8", "TEST_9"])
  end

  it "can remove a list of items to an Array2DHashSet" do
    s1 = Antlr4::Runtime::Array2DHashSet.new(nil, 2, 2)

    i = 0
    while i < 10
      s1.add('TEST_' + i.to_s)
      i += 1
    end

    s1.remove_all(["TEST_5", "TEST_6", "TEST_7", "TEST_8", "TEST_9", "TEST_10"])

    result = []
    i = s1.iterator
    while i.has_next
      result << i.next
    end

    expect(result).to eq(["TEST_0", "TEST_1", "TEST_2", "TEST_3", "TEST_4"])
  end

  it "can convert an Array2DHashSet to a string" do
    s1 = Antlr4::Runtime::Array2DHashSet.new(nil, 2, 2)

    i = 0
    while i < 10
      s1.add('TEST_' + i.to_s)
      i += 1
    end

    result = s1.to_s

    expect(result).to eq("{TEST_0, TEST_1, TEST_2, TEST_3, TEST_4, TEST_5, TEST_6, TEST_7, TEST_8, TEST_9}")
  end
end
