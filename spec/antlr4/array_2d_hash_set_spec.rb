require 'antlr4/runtime/array_2d_hash_set'

RSpec.describe Antlr4::Runtime do

  it "can create an Array2DHashSet" do
    s = Antlr4::Runtime::Array2DHashSet.new

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
end
