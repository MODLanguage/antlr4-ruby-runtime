require '../antlr4/lexer_action'
require 'singleton'

class LexerSkipAction < LexerAction
  include Singleton

  def action_type
    LexerActionType::SKIP
  end

  def position_dependent?
    false
  end

  def execute(lexer)
    lexer.skip
  end

  def hash
    hashcode = 0
    hashcode = MurmurHash.update_int(hashcode, action_type)
    MurmurHash.finish(hashcode, 1)
  end

  def eql?(other)
    other == self
  end

  def to_s
    'skip'
  end
end
