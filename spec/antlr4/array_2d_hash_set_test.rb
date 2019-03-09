require '../antlr4/array_2d_hash_set'

s = Array2DHashSet.new

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
puts result
result = s.get('TEST5')
puts result
result = s.get('TEST9')
puts result
result = s.get('TEST11')
puts result
