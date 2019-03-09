require '../antlr4/lexer_action'
require '../antlr4/lexer_action_type'

class LexerCustomAction < LexerAction
  attr_reader :ruleIndex
  attr_reader :action_index

  def initialize(rule_index, action_index)
    @rule_index = rule_index
    @action_index = action_index
  end

  def action_type
    LexerActionType::CUSTOM
  end

  def position_dependent?
    true
  end

  def execute(lexer)
    lexer.action(nil, @rule_index, @action_index)
  end

  def hash
    hash_code = 0
    hash_code = MurmurHash.update_int(hash_code, action_type)
    hash_code = MurmurHash.update_int(hash_code, rule_index)
    hash_code = MurmurHash.update_int(hash_code, action_index)
    MurmurHash.finish(hash_code, 3)
  end

  def eql?(other)
    if other == self
      return true
    else
      return false unless other.is_a? LexerCustomAction
    end

    @rule_index == other.rule_index && @action_index == other.action_index
  end
end
