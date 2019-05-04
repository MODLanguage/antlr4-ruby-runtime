module Antlr4::Runtime

  class LexerMoreAction < LexerAction
    include Singleton

    def action_type
      LexerActionType::MORE
    end

    def position_dependent?
      false
    end

    def execute(lexer)
      lexer.more
    end

    def hash
      return @_hash unless @_hash.nil?

      hash_code = MurmurHash.hash_int(action_type)

      if !@_hash.nil?
        if hash_code == @_hash
          puts 'Same hash_code for LexerMoreAction'
        else
          puts 'Different hash_code for LexerMoreAction'
        end
      end
      @_hash = hash_code
    end

    def eql?(other)
      other == self
    end

    def to_s
      'more'
    end
  end
end