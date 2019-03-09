require '../antlr4/prediction_context'
require '../antlr4/semantic_context'
require '../antlr4/array_2d_hash_set'

class ATNConfigSet
  attr_accessor :has_semantic_context
  attr_accessor :readonly
  attr_accessor :configs
  attr_accessor :unique_alt
  attr_accessor :dips_into_outer_context
  attr_accessor :full_ctx
  attr_accessor :conflictingAlts

  def initialize(full_ctx = true)
    @full_ctx = full_ctx
    @has_semantic_context = false
    @readonly = false
    @config_lookup = ConfigHashSet.new
    @configs = []
    @dips_into_outer_context = false
    @unique_alt = ATN::INVALID_ALT_NUMBER
  end

  def alts
    alts = BitSet.new
    @configs.each do |config|
      alts.set(config.alt)
    end
    alts
  end

  def add(config, merge_cache = nil)
    raise IllegalStateException, 'This set is readonly' if @readonly

    if config.semantic_context != SemanticContext::NONE
      @has_semantic_context = true
    end

    @dips_into_outer_context = true if config.outer_context_depth > 0

    existing = @config_lookup.get_or_add config
    if existing == config
      @cached_hash_code = -1
      @configs << config
      return true
    end

    root_is_wildcard = !@full_ctx

    merged = PredictionContextUtils.merge(existing.context, config.context, root_is_wildcard, merge_cache)

    existing.reaches_into_outer_context = [existing.reaches_into_outer_context, config.reaches_into_outer_context].max

    if config.precedence_filter_suppressed?
      existing.precedence_filter_suppressed(true)
    end

    existing.context = merged
    true
  end

  def find_first_rule_stop_state
    result = nil

    @configs.each do |config|
      if config.state.is_a? RuleStopState
        result = config
        break
      end
    end
    result
  end

  def empty?
    @config_lookup.empty?
  end

  def to_s
    buf = ''
    buf << '<'
    @configs.each do |c|
      buf << c.to_s << ' '
    end
    buf << '>'

    if @has_semantic_context
      buf << ',hasSemanticContext=' << @has_semantic_context.to_s
    end
    buf << ',uniqueAlt=' << @unique_alt if @unique_alt != ATN::INVALID_ALT_NUMBER
    unless @conflictingAlts.nil?
      buf << ',conflictingAlts=' << @conflictingAlts.to_s
    end
    buf << ',dipsIntoOuterContext' if @dips_into_outer_context
    buf
  end

  class AbstractConfigHashSet < Array2DHashSet
    def initialize(comparator)
      super(comparator, 16, 16)
    end
  end

  class ConfigHashSet < AbstractConfigHashSet
    def initialize
      super(ConfigEqualityComparator.instance)
    end
  end

  def optimize_configs(interpreter)
    raise IllegalStateException, 'This set is readonly' if @readonly
    return if @config_lookup.empty?

    @configs.each do |config|
      config.context = interpreter.cached_context(config.context)
    end
  end

  class ConfigEqualityComparator
    include Singleton

    def hash(o)
      hash_code = 7
      hash_code = 31 * hash_code + o.state.state_number
      hash_code = 31 * hash_code + o.alt
      31 * hash_code + o.semantic_context.hash
    end

    def equals(a, b)
      return true if a == b
      return false if a.nil? || b.nil?

      a.state.state_number == b.state.state_number && a.alt == b.alt && a.semantic_context.eql?(b.semantic_context)
    end
  end

  def size
    @configs.length
  end
end
