require '../antlr4/lexer_action'

class LexerTypeAction < LexerAction
  attr_reader :type

  def initialize(type)
    @type = type
  end

  def action_type
    LexerActionType::TYPE
  end

  def position_dependent?
    false
  end

  def execute(lexer)
    lexer._type = @type
  end

  def hash
    hashcode = 0
    hashcode = MurmurHash.update_int(hashcode, action_type)
    hashcode = MurmurHash.update_int(hashcode, @type)
    MurmurHash.finish(hashcode, 2)
  end

  def eql?(other)
    if other == self
      return true
    else
      return false unless other.is_a? LexerTypeAction
    end

    @type == other.type
  end

  def to_s
    'type(' << @type << ')'
  end
end
