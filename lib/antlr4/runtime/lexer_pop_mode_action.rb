require '../antlr4/lexer_action'
require 'singleton'

class LexerPopModeAction < LexerAction
  include Singleton

  def action_type
    LexerActionType::POP_MODE
  end

  def position_dependent?
    false
  end

  def execute(lexer)
    lexer.pop_mode
  end

  def hash
    hashcode = 0
    hashcode = MurmurHash.update_int(hashcode, action_type)
    MurmurHash.finish(hashcode, 1)
  end

  def equals(other)
    other == self
  end

  def to_s
    'popMode'
  end
end
