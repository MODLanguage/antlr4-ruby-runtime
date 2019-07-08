module Antlr4::Runtime

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
      return @_hash unless @_hash.nil?

      hash_code = RumourHash.calculate([action_type.ordinal, channel])

      unless @_hash.nil?
        if hash_code == @_hash
          puts 'Same hash_code for LexerChannelAction'
        else
          puts 'Different hash_code for LexerChannelAction'
        end
      end
      @_hash = hash_code
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
end
