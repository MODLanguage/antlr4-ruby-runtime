require '../../../../tmp/ruby/MODLParserBaseListener'

class MODLParserTestListener < MODL::MODLParserBaseListener
  def initialize; end

  def enterModl(ctx)
    ctx.modl_structure.each do |str|
      str.enter_rule(self)
    end
  end

  def exitModl(ctx); end

  def enterModl_structure(ctx)
    ctx.modl_map.enter_rule(self) unless ctx.modl_map.nil?
    ctx.modl_array.enter_rule(self) unless ctx.modl_array.nil?
    ctx.modl_top_level_conditional.enter_rule(self) unless ctx.modl_top_level_conditional.nil?
    ctx.modl_pair.enter_rule(self) unless ctx.modl_pair.nil?
  end

  def exitModl_structure(ctx); end

  def enterModl_map(ctx)
    ctx.modl_map_item.each { |i| i.enter_rule(self) }
  end

  def exitModl_map(ctx); end

  def enterModl_array(ctx)
    ctx.modl_array_item.each { |i| i.enter_rule(self) }
    ctx.modl_nb_array.each { |i| i.enter_rule(self) }
  end

  def exitModl_array(ctx); end

  def enterModl_nb_array(ctx)
    ctx.modl_array_item.each { |i| i.enter_rule(self) }
  end

  def exitModl_nb_array(ctx); end

  def enterModl_pair(ctx)
    puts 'QUOTED:' + ctx.QUOTED.to_s unless ctx.QUOTED.nil?
    puts 'STRING:' + ctx.STRING.to_s unless ctx.STRING.nil?
    ctx.modl_value_item.enter_rule(self) unless ctx.modl_value_item.nil?
    ctx.modl_map.enter_rule(self) unless ctx.modl_map.nil?
    ctx.modl_array.enter_rule(self) unless ctx.modl_array.nil?
  end

  def exitModl_pair(ctx); end

  def enterModl_value_item(ctx)
    ctx.modl_value.enter_rule(self) unless ctx.modl_value.nil?
    ctx.modl_value_conditional.enter_rule(self) unless ctx.modl_value_conditional.nil?
  end

  def exitModl_value_item(ctx); end

  def enterModl_top_level_conditional(ctx)
    ctx.modl_condition_test.each { |i| i.enter_rule(self) }
    ctx.modl_top_level_conditional_return.each { |i| i.enter_rule(self) }
  end

  def exitModl_top_level_conditional(ctx); end

  def enterModl_top_level_conditional_return(ctx)
    ctx.modl_structure.each do |str|
      str.enter_rule(self)
    end
  end

  def exitModl_top_level_conditional_return(ctx); end

  def enterModl_map_conditional(ctx)
    ctx.modl_structure.each do |str|
      str.enter_rule(self)
    end
  end

  def exitModl_map_conditional(ctx); end

  def enterModl_map_conditional_return(ctx)
    ctx.modl_structure.each do |str|
      str.enter_rule(self)
    end
  end

  def exitModl_map_conditional_return(ctx); end

  def enterModl_map_item(ctx)
    ctx.modl_pair.enter_rule(self) unless ctx.modl_pair.nil?
    ctx.modl_map_conditional.enter_rule(self) unless ctx.modl_map_conditional.nil?
  end

  def exitModl_map_item(ctx); end

  def enterModl_array_conditional(ctx)
    ctx.modl_condition_test.each { |i| i.enter_rule(self) }
    ctx.modl_array_conditional_return.each { |i| i.enter_rule(self) }
  end

  def exitModl_array_conditional(ctx); end

  def enterModl_array_conditional_return(ctx)
    ctx.modl_array_item.each { |i| i.enter_rule(self) }

    ctx.NEWLINE.each { |t| puts t.to_s }
    ctx.SC.each { |t| puts t.to_s }
  end

  def exitModl_array_conditional_return(ctx); end

  def enterModl_array_item(ctx)
    ctx.modl_array_value_item.enter_rule(self) unless ctx.modl_array_value_item.nil?
    ctx.modl_array_conditional.enter_rule(self) unless ctx.modl_array_conditional.nil?
  end

  def exitModl_array_item(ctx); end

  def enterModl_value_conditional(ctx)
    ctx.modl_condition_test.each { |i| i.enter_rule(self) }
    ctx.modl_value_conditional_return.each { |i| i.enter_rule(self) }
  end

  def exitModl_value_conditional(ctx); end

  def enterModl_value_conditional_return(ctx)
    ctx.modl_value_item.each { |i| i.enter_rule(self) }
  end

  def exitModl_value_conditional_return(ctx); end

  def enterModl_condition_test(ctx)
    ctx.modl_condition.each { |i| i.enter_rule(self) }
    ctx.modl_condition_group.each { |i| i.enter_rule(self) }
  end

  def exitModl_condition_test(ctx); end

  def enterModl_operator(ctx); end

  def exitModl_operator(ctx); end

  def enterModl_condition(ctx)
    ctx.modl_value.each { |i| i.enter_rule(self) }
    ctx.modl_operator.enter_rule(self) unless ctx.modl_operator.nil?
  end

  def exitModl_condition(ctx); end

  def enterModl_condition_group(ctx)
    ctx.modl_structure.each do |str|
      str.enter_rule(self)
    end
  end

  def exitModl_condition_group(ctx); end

  def enterModl_value(ctx)
    ctx.modl_map.enter_rule(self) unless ctx.modl_map.nil?
    ctx.modl_array.enter_rule(self) unless ctx.modl_array.nil?
    ctx.modl_nb_array.enter_rule(self) unless ctx.modl_nb_array.nil?
    ctx.modl_pair.enter_rule(self) unless ctx.modl_pair.nil?
    ctx.modl_map.enter_rule(self) unless ctx.modl_map.nil?
    ctx.modl_map.enter_rule(self) unless ctx.modl_map.nil?

    puts 'QUOTED:' + ctx.QUOTED.to_s unless ctx.QUOTED.nil?
    puts 'NUMBER:' + ctx.NUMBER.to_s unless ctx.NUMBER.nil?
    puts 'STRING:' + ctx.STRING.to_s unless ctx.STRING.nil?
    puts 'TRUE:' + ctx.TRUE.to_s unless ctx.TRUE.nil?
    puts 'FALSE:' + ctx.FALSE.to_s unless ctx.FALSE.nil?
    puts 'NULL:' + ctx.NULL.to_s unless ctx.NULL.nil?
  end

  def exitModl_value(ctx); end

  def enterModl_array_value_item(ctx)
    ctx.modl_map.enter_rule(self) unless ctx.modl_map.nil?
    ctx.modl_pair.enter_rule(self) unless ctx.modl_pair.nil?
    ctx.modl_array.enter_rule(self) unless ctx.modl_array.nil?

    puts 'QUOTED:' + ctx.QUOTED.to_s unless ctx.QUOTED.nil?
    puts 'NUMBER:' + ctx.NUMBER.to_s unless ctx.NUMBER.nil?
    puts 'STRING:' + ctx.STRING.to_s unless ctx.STRING.nil?
    puts 'TRUE:' + ctx.TRUE.to_s unless ctx.TRUE.nil?
    puts 'FALSE:' + ctx.FALSE.to_s unless ctx.FALSE.nil?
    puts 'NULL:' + ctx.NULL.to_s unless ctx.NULL.nil?
  end

  def exitModl_array_value_item(ctx); end

  def enterEveryRule(ctx)
    ctx.modl_structure.each do |str|
      str.enter_rule(self)
    end
  end

  def exitEveryRule(ctx); end

  def visitTerminal(node); end

  def visitErrorNode(node); end
end
