class ATNConfig
  SUPPRESS_PRECEDENCE_FILTER = 0x40000000

  attr_accessor :state
  attr_accessor :alt
  attr_accessor :context
  attr_accessor :target
  attr_accessor :reaches_into_outer_context
  attr_accessor :semantic_context

  def initialize
    @reaches_into_outer_context = 0
    @alt = 0
  end

  def atn_config_copy(old)
    @state = old.state
    @alt = old.alt
    @context = old.context
    @semantic_context = old.semantic_context
    @reaches_into_outer_context = old.reaches_into_outer_context
  end

  def atn_config1(state, alt, context)
    atn_config2(state, alt, context, SemanticContext::NONE)
  end

  def atn_config2(state, alt, context, semantic_context)
    @state = state
    @alt = alt
    @context = context
    @semantic_context = semantic_context
  end

  def atn_config3(c, state)
    atn_config7(c, state, c.context, c.semantic_context)
  end

  def atn_config4(c, state, semantic_context)
    atn_config7(c, state, c.context, semantic_context)
  end

  def atn_config5(c, semantic_context)
    atn_config7(c, c.state, c.context, semantic_context)
  end

  def atn_config6(c, state, context)
    atn_config7(c, state, context, c.semantic_context)
  end

  def atn_config7(c, state, context, semantic_context)
    @state = state
    @alt = c.alt
    @context = context
    @semantic_context = semantic_context
    @reaches_into_outer_context = c.reaches_into_outer_context
  end

  def outer_context_depth
    (@reaches_into_outer_context & ~SUPPRESS_PRECEDENCE_FILTER)
  end

  def precedence_filter_suppressed?
    (@reaches_into_outer_context & SUPPRESS_PRECEDENCE_FILTER) != 0
  end

  def precedence_filter_suppressed(value)
    if value
      @reaches_into_outer_context |= 0x40000000
    else
      @reaches_into_outer_context &= ~SUPPRESS_PRECEDENCE_FILTER
    end
  end

  def to_s
    to_s2(nil, true)
  end

  def to_s2(_recog = nil, show_alt = false)
    buf = ''
    buf << '('
    buf << @state.to_s
    if show_alt
      buf << ','
      buf << @alt.to_s
    end
    unless @context.nil?
      buf << ',['
      buf << @context.to_s
      buf << ']'
    end
    if !@semantic_context.nil? && @semantic_context != SemanticContext::NONE
      buf << ','
      buf << @semantic_context.to_s
    end
    buf << ',up=' << outer_context_depth.to_s if outer_context_depth > 0
    buf << ')'
    buf
  end

  def eql?(other)
    if self == other
      return true
    elsif other.nil?
      return false
    end

    @state.state_number == other.state.state_number && @alt == other.alt && (@context == other.context || (!@context.nil? && @context.<=>(other.context))) && @semantic_context.<=>(other.semantic_context) && precedence_filter_suppressed? == other.precedence_filter_suppressed?
  end

  def hash
    hash_code = 7
    hash_code = MurmurHash.update_int(hash_code, @state.state_number)
    hash_code = MurmurHash.update_int(hash_code, @alt)
    hash_code = MurmurHash.update_obj(hash_code, @context)
    hash_code = MurmurHash.update_obj(hash_code, @semantic_context)
    MurmurHash.finish(hash_code, 4)
  end
end
