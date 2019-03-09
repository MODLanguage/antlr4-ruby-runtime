require '../antlr4/atn_config_set'
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
      @configs.each do |c|
        alts.add(c.alt)
      end
    end
    return nil if alts.empty?

    alts
  end

  def hash
    hash = 7
    hash = MurmurHash.update_int(hash, configs.hash)
    MurmurHash.finish(hash, 1)
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
