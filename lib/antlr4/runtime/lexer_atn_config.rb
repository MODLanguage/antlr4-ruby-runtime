require '../antlr4/atn_config'

class LexerATNConfig < ATNConfig
  attr_accessor :passed_through_non_greedy_decision
  attr_accessor :lexer_action_executor

  def initialize
    super
    @passed_through_non_greedy_decision = false
    @lexer_action_executor = nil
  end

  def lexer_atn_config1(state, alt, context)
    atn_config2(state, alt, context, SemanticContext::NONE)
    @passed_through_non_greedy_decision = false
    @lexer_action_executor = nil
  end

  def lexer_atn_config2(state, alt, context, lexer_action_executor)
    atn_config7(state, alt, context, SemanticContext::NONE)
    @lexer_action_executor = lexer_action_executor
    @passed_through_non_greedy_decision = false
  end

  def lexer_atn_config3(c, state)
    atn_config7(c, state, c.context, c.semantic_context)
    @lexer_action_executor = c.lexer_action_executor
    @passed_through_non_greedy_decision = check_non_greedy_decision(c, state)
  end

  def lexer_atn_config4(c, state, lexer_action_executor)
    atn_config7(c, state, c.context, c.semantic_context)
    @lexer_action_executor = lexer_action_executor
    @passed_through_non_greedy_decision = check_non_greedy_decision(c, state)
  end

  def lexer_atn_config5(c, state, context)
    atn_config7(c, state, context, c.semantic_context)
    @lexer_action_executor = c.lexer_action_executor
    @passed_through_non_greedy_decision = check_non_greedy_decision(c, state)
  end

  def check_non_greedy_decision(source, target)
    source.passed_through_non_greedy_decision || target.is_a?(DecisionState) && target.non_greedy
  end
end
