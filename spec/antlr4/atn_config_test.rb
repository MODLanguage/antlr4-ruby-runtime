require '../antlr4/atn_config'

cfg = ATNConfig.new

depth = cfg.outer_context_depth

puts 'depth is not a number' unless depth.is_a? Integer
puts depth if depth > 0
puts depth if depth <= 0
