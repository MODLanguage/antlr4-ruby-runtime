require '../antlr4/lexer_action'

class LexerModeAction < LexerAction
  attr_reader :mode

  def initialize(mode)
    @mode = mode
  end

  def action_type
    LexerActionType::MODE
  end

  def position_dependent?
    false
  end

  def execute(lexer)
    lexer.mode(@mode)
  end

  def hash
    hashcode = 0
    hashcode = MurmurHash.update_int(hashcode, action_type)
    hashcode = MurmurHash.update_int(hashcode, mode)
    MurmurHash.finish(hashcode, 2)
  end

  def eql?(other)
    if other == self
      return true
    else
      return false unless other.is_a? LexerModeAction
    end

    @mode == other.mode
  end

  def to_s
    'mode(' << @mode << ')'
  end
end
