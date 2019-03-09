require '../antlr4/lexer_action'

class LexerIndexedCustomAction < LexerAction
  attr_reader :action
  attr_reader :offset

  def initialize(offset, action)
    @offset = offset
    @action = action
  end

  def action_type
    @action.action_type
  end

  def position_dependent?
    true
  end

  def execute(lexer) # assume the input stream position was properly set by the calling code
    @action.execute(lexer)
  end

  def hash
    hash = 0
    hash = MurmurHash.update_int(hash, offset)
    hash = MurmurHash.update_obj(hash, action)
    MurmurHash.finish(hash, 2)
  end

  def eql?(other)
    if other == self
      return true
    else
      return false unless other.is_a? LexerIndexedCustomAction
    end

    @offset == other.offset && @action == other.action
  end
end
