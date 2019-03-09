require '../antlr4/lexer_action'
require '../antlr4/lexer_action_type'

class LexerChannelAction < LexerAction
  attr_reader :channel

  def initialize(channel)
    @channel = channel
  end

  def action_type
    LexerActionType::CHANNEL
  end

  def position_dependent?
    false
  end

  def execute(lexer)
    lexer.setChannel(@channel)
  end

  def hash
    hash_code = 0
    hash_code = MurmurHash.update_int(hash_code, action_type.ordinal)
    hash_code = MurmurHash.update_int(hash_code, channel)
    MurmurHash.finish(hash_code, 2)
  end

  def eql?(other)
    if other == self
      return true
    else
      return false unless other.is_a? LexerChannelAction
    end

    @channel == other.channel
  end

  def to_s
    'channel(' << @channel.to_s << ')'
  end
end
