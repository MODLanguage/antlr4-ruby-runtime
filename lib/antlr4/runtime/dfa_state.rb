module Antlr4::Runtime
  class DFAState
    attr_accessor :state_number

    attr_accessor :configs

    attr_accessor :edges

    attr_accessor :is_accept_state

    attr_accessor :prediction

    attr_accessor :lexer_action_executor

    attr_accessor :requires_full_context

    attr_accessor :predicates

    def initialize(x = nil)
      @is_accept_state = false
      @edges = []
      @state_number = -1
      @_hash = nil

      if x.nil?
        @configs = ATNConfigSet.new
      elsif x.is_a?(ATNConfigSet)
        @configs = x
      else
        @state_number = x
      end
    end

    class PredPrediction
      attr_accessor :pred # never null at least SemanticContext::NONE
      attr_accessor :alt

      def initiailize(pred, alt)
        @alt = alt
        @pred = pred
      end

      def to_s
        '(' + @pred.to_s + ', ' + @alt.to_s + ')'
      end
    end

    def initialize_state_number(stateNumber)
      @state_number = stateNumber
    end

    def initialize_configs(configs)
      @configs = configs
    end

    def alt_set
      alts = Set.new
      unless @configs.nil?
        i = 0
        while i < @configs.length
          c = @configs[i]
          alts.add(c.alt)
          i += 1
        end
      end
      return nil if alts.empty?

      alts
    end

    def hash
      return @_hash unless @_hash.nil?

      hash_code = RumourHash.calculate([configs.hash])

      if !@_hash.nil?
        if hash_code == @_hash
          puts 'Same hash_code for DFAState'
        else
          puts 'Different hash_code for DFAState'
        end
      end

      @_hash = hash_code
    end

    def equals?(o) # compare set of ATN configurations in this set with other
      return true if self == o
      return false unless o.is_a? DFAState

      @configs.eql?(o.configs)
    end

    def to_s
      buf = ''
      buf << @state_number.to_s << ':' << @configs.to_s
      if @is_accept_state
        buf << '=>'
        buf << if !@predicates.nil?
                 @predicates.to_s
               else
                 @prediction.to_s
               end
      end

      buf.to_s
    end
  end
end
