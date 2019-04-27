module Antlr4::Runtime

  class LexerPushModeAction < LexerAction
    attr_reader :mode

    def initialize(mode)
      @mode = mode
    end

    def action_type
      LexerActionType::PUSH_MODE
    end

    def position_dependent?
      false
    end

    def execute(lexer)
      lexer.push_mode(@mode)
    end

    def hash
      return @_hash unless @_hash.nil?

      hash_code = 0
      hash_code = MurmurHash.update_int(hash_code, action_type)
      hash_code = MurmurHash.update_int(hash_code, mode)
      hash_code = MurmurHash.finish(hash_code, 2)
      if !@_hash.nil?
        if hash_code == @_hash
          puts 'Same hash_code for LexerPushModeAction'
        else
          puts 'Different hash_code for LexerPushModeAction'
        end
      end
      @_hash = hash_code
    end

    def eql?(other)
      if other == self
        return true
      else
        return false unless other.is_a? LexerPushModeAction
      end

      @mode == other.mode
    end

    def to_s
      'pushMode(' << @mode << ')'
    end
  end
end