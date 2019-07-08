module Antlr4::Runtime

  class LexerCustomAction < LexerAction
    attr_reader :rule_index
    attr_reader :action_index

    def initialize(rule_index, action_index)
      @rule_index = rule_index
      @action_index = action_index
    end

    def action_type
      LexerActionType::CUSTOM
    end

    def position_dependent?
      true
    end

    def execute(lexer)
      lexer.action(nil, @rule_index, @action_index)
    end

    def hash
      return @_hash unless @_hash.nil?

      hash_code = RumourHash.calculate([action_type, rule_index, action_index])

      unless @_hash.nil?
        if hash_code == @_hash
          puts 'Same hash_code for LexerCustomAction'
        else
          puts 'Different hash_code for LexerCustomAction'
        end
      end

      @_hash = hash_code
    end

    def eql?(other)
      if other == self
        return true
      else
        return false unless other.is_a? LexerCustomAction
      end

      @rule_index == other.rule_index && @action_index == other.action_index
    end
  end
end
