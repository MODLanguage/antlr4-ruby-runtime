require 'spec_helper'

RSpec.describe Antlr4::Runtime do

  it "can create IntervalSets using IntervalSet::of" do
    set1 = Antlr4::Runtime::IntervalSet.of(1)
    set2 = Antlr4::Runtime::IntervalSet.of(1, 2)
    expect(set1.intervals).not_to be(nil)
    expect(set1.intervals.length).to eq(1)
    expect(set1.intervals[0].a).to eq(1)
    expect(set1.intervals[0].b).to eq(1)

    expect(set2.intervals).not_to be(nil)
    expect(set2.intervals.length).to eq(1)
    expect(set2.intervals[0].a).to eq(1)
    expect(set2.intervals[0].b).to eq(2)
  end

  it "can create IntervalSet with no params" do
    set = Antlr4::Runtime::IntervalSet.new()
    expect(set.intervals).not_to be(nil)
    expect(set.intervals.length).to eq(0)
  end

  it "can create IntervalSet with one int param" do
    set = Antlr4::Runtime::IntervalSet.new(1)
    expect(set.intervals.length).to eq(1)
    expect(set.intervals[0].a).to eq(1)
    expect(set.intervals[0].b).to eq(1)
  end

  it "can create IntervalSet with two int params" do
    set = Antlr4::Runtime::IntervalSet.new(1, 2)
    expect(set.intervals.length).to eq(1)
    expect(set.intervals[0].a).to eq(1)
    expect(set.intervals[0].b).to eq(2)
  end

  it "can create IntervalSet with two int params, b < a" do
    set = Antlr4::Runtime::IntervalSet.new(3, 2)
    expect(set.intervals.length).to eq(0)
  end

  it "can add a disjopint Interval to an IntervalSet" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 2)

    set1.add(Antlr4::Runtime::Interval.new(4, 5))
    expect(set1.intervals.length).to eq(2)
    expect(set1.intervals[0].a).to eq(1)
    expect(set1.intervals[0].b).to eq(2)
    expect(set1.intervals[1].a).to eq(4)
    expect(set1.intervals[1].b).to eq(5)
  end

  it "can add an overlapping Interval to an IntervalSet" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 4)

    set1.add(Antlr4::Runtime::Interval.new(3, 6))
    expect(set1.intervals.length).to eq(1)
    expect(set1.intervals[0].a).to eq(1)
    expect(set1.intervals[0].b).to eq(6)
  end

  it "can add two disjoint IntervalSets " do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 2)
    set2 = Antlr4::Runtime::IntervalSet.new(4, 5)

    set1.add_all(set2)
    expect(set1.intervals.length).to eq(2)
    expect(set1.intervals[0].a).to eq(1)
    expect(set1.intervals[0].b).to eq(2)
    expect(set1.intervals[1].a).to eq(4)
    expect(set1.intervals[1].b).to eq(5)
  end

  it "can add two overlapping IntervalSets " do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 4)
    set2 = Antlr4::Runtime::IntervalSet.new(3, 6)

    set1.add_all(set2)
    expect(set1.intervals.length).to eq(1)
    expect(set1.intervals[0].a).to eq(1)
    expect(set1.intervals[0].b).to eq(6)
  end

  it "can subtract a disjoint IntervalSet from an IntervalSet" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 3)
    set2 = Antlr4::Runtime::IntervalSet.new(4, 6)

    set1.subtract(set2)
    expect(set1.intervals.length).to eq(1)
    expect(set1.intervals[0].a).to eq(1)
    expect(set1.intervals[0].b).to eq(3)
  end

  it "can subtract an overlapping IntervalSet from an IntervalSet 1" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 10)
    set2 = Antlr4::Runtime::IntervalSet.new(4, 6)

    set3 = set1.subtract(set2)
    expect(set3.intervals.length).to eq(2)
    expect(set3.intervals[0].a).to eq(1)
    expect(set3.intervals[0].b).to eq(3)
    expect(set3.intervals[1].a).to eq(7)
    expect(set3.intervals[1].b).to eq(10)
  end

  it "can subtract an overlapping IntervalSet from an IntervalSet 2" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 10)
    set2 = Antlr4::Runtime::IntervalSet.new(5, 10)

    set3 = set1.subtract(set2)
    expect(set3.intervals.length).to eq(1)
    expect(set3.intervals[0].a).to eq(1)
    expect(set3.intervals[0].b).to eq(4)
  end

  it "can subtract an overlapping IntervalSet from an IntervalSet 3" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 10)
    set2 = Antlr4::Runtime::IntervalSet.new(1, 5)

    set3 = set1.subtract(set2)
    expect(set3.intervals.length).to eq(1)
    expect(set3.intervals[0].a).to eq(6)
    expect(set3.intervals[0].b).to eq(10)
  end

  it "can subtract a nonoverlapping IntervalSet from an IntervalSet 4" do
    set1 = Antlr4::Runtime::IntervalSet.new(7, 10)
    set2 = Antlr4::Runtime::IntervalSet.new(1, 3)

    set3 = set1.subtract(set2)
    expect(set3.intervals.length).to eq(1)
    expect(set3.intervals[0].a).to eq(7)
    expect(set3.intervals[0].b).to eq(10)
  end

  it "can OR two overlapping IntervalSets" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 10)
    set2 = Antlr4::Runtime::IntervalSet.new(1, 5)

    set3 = set1.or(set2)
    expect(set3.intervals.length).to eq(1)
    expect(set3.intervals[0].a).to eq(1)
    expect(set3.intervals[0].b).to eq(10)
  end

  it "can OR two nonoverlapping IntervalSets" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 5)
    set2 = Antlr4::Runtime::IntervalSet.new(7, 10)

    set3 = set1.or(set2)
    expect(set3.intervals.length).to eq(2)
    expect(set3.intervals[0].a).to eq(1)
    expect(set3.intervals[0].b).to eq(5)
    expect(set3.intervals[1].a).to eq(7)
    expect(set3.intervals[1].b).to eq(10)
  end

  it "can OR multiple IntervalSets 1" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 3)
    set2 = Antlr4::Runtime::IntervalSet.new(5, 10)
    set3 = Antlr4::Runtime::IntervalSet.new(12, 14)

    set4 = Antlr4::Runtime::IntervalSet.or_sets([set1, set2, set3])
    expect(set4.intervals.length).to eq(3)
    expect(set4.intervals[0].a).to eq(1)
    expect(set4.intervals[0].b).to eq(3)
    expect(set4.intervals[1].a).to eq(5)
    expect(set4.intervals[1].b).to eq(10)
    expect(set4.intervals[2].a).to eq(12)
    expect(set4.intervals[2].b).to eq(14)
  end

  it "can OR multiple IntervalSets 2" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 6)
    set2 = Antlr4::Runtime::IntervalSet.new(5, 10)
    set3 = Antlr4::Runtime::IntervalSet.new(10, 14)

    set4 = Antlr4::Runtime::IntervalSet.or_sets([set1, set2, set3])
    expect(set4.intervals.length).to eq(1)
    expect(set4.intervals[0].a).to eq(1)
    expect(set4.intervals[0].b).to eq(14)
  end

  it "can clear an interval set" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 6)
    expect(set1.intervals.length).to eq(1)
    expect(set1.intervals[0].a).to eq(1)
    expect(set1.intervals[0].b).to eq(6)
    set1.clear
    expect(set1.intervals.length).to eq(0)
  end

  it "can add an adjacent interval to an existing interval" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 6)
    set1.add_interval(Antlr4::Runtime::Interval.new(7, 8))
    expect(set1.intervals.length).to eq(1)
    expect(set1.intervals[0].a).to eq(1)
    expect(set1.intervals[0].b).to eq(8)
  end

  it "can add an adjacent interval between two existing intervals" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 4)
    set1.add_interval(Antlr4::Runtime::Interval.new(7, 8))
    expect(set1.intervals.length).to eq(2)
    expect(set1.intervals[0].a).to eq(1)
    expect(set1.intervals[0].b).to eq(4)
    expect(set1.intervals[1].a).to eq(7)
    expect(set1.intervals[1].b).to eq(8)

    set1.add_interval(Antlr4::Runtime::Interval.new(5, 6))
    expect(set1.intervals.length).to eq(1)
    expect(set1.intervals[0].a).to eq(1)
    expect(set1.intervals[0].b).to eq(8)
  end

  it "can add a disjoint interval before an existing interval" do
    set1 = Antlr4::Runtime::IntervalSet.new(10, 14)
    set1.add_interval(Antlr4::Runtime::Interval.new(1, 8))
    expect(set1.intervals.length).to eq(2)
    expect(set1.intervals[0].a).to eq(1)
    expect(set1.intervals[0].b).to eq(8)
    expect(set1.intervals[1].a).to eq(10)
    expect(set1.intervals[1].b).to eq(14)
  end

  it "can complement an IntervalSet 1" do
    set1 = Antlr4::Runtime::IntervalSet.new(10, 14)
    set2 = set1.complement(0, 100)
    expect(set2.intervals.length).to eq(2)
    expect(set2.intervals[0].a).to eq(0)
    expect(set2.intervals[0].b).to eq(9)
    expect(set2.intervals[1].a).to eq(15)
    expect(set2.intervals[1].b).to eq(100)
  end

  it "can complement an IntervalSet 2" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 14)
    set2 = set1.complement(5, 10)
    expect(set2.intervals.length).to eq(0)
  end

  it "can AND two IntervalSets 1" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 3)
    set2 = Antlr4::Runtime::IntervalSet.new(6, 8)
    set3 = set1.and(set2)
    expect(set3.intervals.length).to eq(0)
  end

  it "can AND two IntervalSets 2" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 8)
    set2 = Antlr4::Runtime::IntervalSet.new(6, 10)
    set3 = set1.and(set2)
    expect(set3.intervals.length).to eq(1)
    expect(set3.intervals[0].a).to eq(6)
    expect(set3.intervals[0].b).to eq(8)
  end

  it "can AND two IntervalSets 3" do
    set1 = Antlr4::Runtime::IntervalSet.new(1, 8)
    set2 = Antlr4::Runtime::IntervalSet.new(2, 6)
    set3 = set1.and(set2)
    expect(set3.intervals.length).to eq(1)
    expect(set3.intervals[0].a).to eq(2)
    expect(set3.intervals[0].b).to eq(6)
  end

  it "can AND two IntervalSets 4" do
    set1 = Antlr4::Runtime::IntervalSet.new(2, 6)
    set2 = Antlr4::Runtime::IntervalSet.new(1, 8)
    set3 = set1.and(set2)
    expect(set3.intervals.length).to eq(1)
    expect(set3.intervals[0].a).to eq(2)
    expect(set3.intervals[0].b).to eq(6)
  end

  it "can compare interval sets" do
    set1 = Antlr4::Runtime::IntervalSet.new(2, 6)
    set2 = Antlr4::Runtime::IntervalSet.new(1, 8)
    set3 = Antlr4::Runtime::IntervalSet.new(1, 8)

    expect(set1 == set2).to be(false)
    expect(set2 == set3).to be(true)
  end

  it "can find the max and min elements" do
    set1 = Antlr4::Runtime::IntervalSet.new(2, 4)
    set1.add_interval(Antlr4::Runtime::Interval.new(7,10))
    set1.add_interval(Antlr4::Runtime::Interval.new(15,19))

    expect(set1.max_element).to eq(19)
    expect(set1.min_element).to eq(2)
  end

  it "can generate a hash value" do
    set1 = Antlr4::Runtime::IntervalSet.new(2, 4)
    set1.add_interval(Antlr4::Runtime::Interval.new(7,10))
    set1.add_interval(Antlr4::Runtime::Interval.new(15,19))

    expect(set1.hash).not_to be(nil)
    expect(set1.hash).to eq(3624189328134123641)
  end

  it "can convert an IntervalSet top an integer list" do
    set1 = Antlr4::Runtime::IntervalSet.new(2, 4)
    set1.add_interval(Antlr4::Runtime::Interval.new(7,10))
    set1.add_interval(Antlr4::Runtime::Interval.new(15,19))

    expect(set1.to_integer_list).to eq([2, 3, 4, 7, 8, 9, 10, 15, 16, 17, 18, 19])
  end

  it "can convert an IntervalSet top an integer set" do
    set1 = Antlr4::Runtime::IntervalSet.new(2, 4)
    set1.add_interval(Antlr4::Runtime::Interval.new(7,10))
    set1.add_interval(Antlr4::Runtime::Interval.new(15,19))

    expect(set1.to_set).to eq([2, 3, 4, 7, 8, 9, 10, 15, 16, 17, 18, 19].to_set)
  end

  it "can get the size of an IntervalSet 1" do
    set1 = Antlr4::Runtime::IntervalSet.new(2, 4)
    set1.add_interval(Antlr4::Runtime::Interval.new(7,10))
    set1.add_interval(Antlr4::Runtime::Interval.new(15,19))

    expect(set1.size).to eq(12)
  end

  it "can get the size of an IntervalSet 2" do
    set1 = Antlr4::Runtime::IntervalSet.new(2, 4)

    expect(set1.size).to eq(3)
  end

  it "can check whether an IntervalSet contains a value 1" do
    set1 = Antlr4::Runtime::IntervalSet.new(2, 6)
    set1.add_interval(Antlr4::Runtime::Interval.new(8,10))
    set1.add_interval(Antlr4::Runtime::Interval.new(13,15))
    set1.add_interval(Antlr4::Runtime::Interval.new(19,21))

    expect(set1.contains(1)).to be(false)
    expect(set1.contains(7)).to be(false)
    expect(set1.contains(11)).to be(false)
    expect(set1.contains(12)).to be(false)
    expect(set1.contains(16)).to be(false)
    expect(set1.contains(17)).to be(false)
    expect(set1.contains(18)).to be(false)
    expect(set1.contains(22)).to be(false)

    expect(set1.contains(2)).to be(true)
    expect(set1.contains(3)).to be(true)
    expect(set1.contains(4)).to be(true)
    expect(set1.contains(5)).to be(true)
    expect(set1.contains(6)).to be(true)
    expect(set1.contains(8)).to be(true)
    expect(set1.contains(9)).to be(true)
    expect(set1.contains(10)).to be(true)
    expect(set1.contains(13)).to be(true)
    expect(set1.contains(14)).to be(true)
    expect(set1.contains(15)).to be(true)
    expect(set1.contains(19)).to be(true)
    expect(set1.contains(20)).to be(true)
    expect(set1.contains(21)).to be(true)
  end

  it "can remove a value from an IntervalSet 1" do
    set1 = Antlr4::Runtime::IntervalSet.new(2, 4)
    set1.add_interval(Antlr4::Runtime::Interval.new(7,10))
    set1.add_interval(Antlr4::Runtime::Interval.new(15,19))

    set1.remove(1)
    expect(set1.intervals.length).to eq(3)
    expect(set1.intervals[0].a).to eq(2)
    expect(set1.intervals[0].b).to eq(4)
    expect(set1.intervals[1].a).to eq(7)
    expect(set1.intervals[1].b).to eq(10)
    expect(set1.intervals[2].a).to eq(15)
    expect(set1.intervals[2].b).to eq(19)

    set1.remove(2)
    expect(set1.intervals.length).to eq(3)
    expect(set1.intervals[0].a).to eq(3)
    expect(set1.intervals[0].b).to eq(4)
    expect(set1.intervals[1].a).to eq(7)
    expect(set1.intervals[1].b).to eq(10)
    expect(set1.intervals[2].a).to eq(15)
    expect(set1.intervals[2].b).to eq(19)

    set1.remove(17)
    expect(set1.intervals.length).to eq(4)
    expect(set1.intervals[0].a).to eq(3)
    expect(set1.intervals[0].b).to eq(4)
    expect(set1.intervals[1].a).to eq(7)
    expect(set1.intervals[1].b).to eq(10)
    expect(set1.intervals[2].a).to eq(15)
    expect(set1.intervals[2].b).to eq(16)
    expect(set1.intervals[3].a).to eq(18)
    expect(set1.intervals[3].b).to eq(19)

    set1.remove(3)
    set1.remove(4)
    expect(set1.intervals.length).to eq(3)
    expect(set1.intervals[0].a).to eq(7)
    expect(set1.intervals[0].b).to eq(10)
    expect(set1.intervals[1].a).to eq(15)
    expect(set1.intervals[1].b).to eq(16)
    expect(set1.intervals[2].a).to eq(18)
    expect(set1.intervals[2].b).to eq(19)

    set1.remove(19)
    expect(set1.intervals.length).to eq(3)
    expect(set1.intervals[0].a).to eq(7)
    expect(set1.intervals[0].b).to eq(10)
    expect(set1.intervals[1].a).to eq(15)
    expect(set1.intervals[1].b).to eq(16)
    expect(set1.intervals[2].a).to eq(18)
    expect(set1.intervals[2].b).to eq(18)
  end

end
