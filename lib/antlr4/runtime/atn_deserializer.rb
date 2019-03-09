require 'ostruct'
require '../antlr4/atn_deserialization_options'
require '../antlr4/uuid'
require '../antlr4/atn_type'
require '../antlr4/atn_state'
require '../antlr4/atn'
require '../antlr4/block_start_state'
require '../antlr4/transition'

require '../antlr4/basic_state'
require '../antlr4/rule_start_state'
require '../antlr4/basic_block_start_state'
require '../antlr4/plus_block_start_state'
require '../antlr4/star_block_start_state'
require '../antlr4/tokens_start_state'
require '../antlr4/rule_stop_state'
require '../antlr4/block_end_state'
require '../antlr4/star_loopback_state'
require '../antlr4/star_loop_entry_state'
require '../antlr4/plus_loopback_state'
require '../antlr4/loop_end_state'

require '../antlr4/epsilon_transition'
require '../antlr4/range_transition'
require '../antlr4/range_transition'
require '../antlr4/rule_transition'
require '../antlr4/predicate_transition'
require '../antlr4/precedence_predicate_transition'
require '../antlr4/atom_transition'
require '../antlr4/action_transition'
require '../antlr4/set_transition'
require '../antlr4/not_set_transition'
require '../antlr4/wildcard_transition'
require '../antlr4/lexer_action_type'
require '../antlr4/lexer_channel_action'
require '../antlr4/lexer_custom_action'
require '../antlr4/lexer_mode_action'
require '../antlr4/lexer_more_action'
require '../antlr4/lexer_pop_mode_action'
require '../antlr4/lexer_push_mode_action'
require '../antlr4/lexer_skip_action'
require '../antlr4/lexer_type_action'

class UnsupportedOperationException < StandardError
end

class IllegalStateException < StandardError
end

class ATNDeserializer
  SERIALIZED_VERSION = 3

  class << self
    attr_accessor :SERIALIZED_Uuid
    attr_accessor :SERIALIZED_VERSION
    @@base_serialized_uuid = UUID.from_string('33761B2D-78BB-4A43-8B0B-4F5BEE8AACF3')
    @@added_precedence_transitions = UUID.from_string('1DA0C57D-6C06-438A-9B27-10BCB3CE0F61')
    @@added_lexer_actions = UUID.from_string('AADB8D7E-AEEF-4415-AD2B-8204D6CF042E')
    @@added_unicode_smp = UUID.from_string('59627784-3BE5-417A-B9EB-8131A7286089')
    @@supported_uuids = [@@base_serialized_uuid, @@added_precedence_transitions, @@added_lexer_actions, @@added_unicode_smp]

    @@serialized_uuid = @@added_unicode_smp
  end

  class UnicodeDeserializer
    def read_unicode(data, p)
      data[p]
    end

    def size
      1
    end
  end

  class UnicodeDeserializingMode
    UNICODE_BMP = 1
    UNICODE_SMP = 2
  end

  def self.unicode_deserializer(mode)
    if mode == UnicodeDeserializingMode::UNICODE_BMP
      UnicodeDeserializer.new
    else
      UnicodeDeserializer.new
    end
  end

  def initialize(deserialization_options = nil)
    @deserialization_options = if deserialization_options.nil?
                                 ATNDeserializationOptions.get_default_options
                               else
                                 deserialization_options
                               end
  end

  def feature_supported?(feature, actual_uuid)
    feature_index = @@supported_uuids.index(feature)
    return false if feature_index < 0

    @@supported_uuids.index(actual_uuid) >= feature_index
  end

  def deserialize(serialized_data)
    data = serialized_data.codepoints

    i = 1
    while i < data.length
      data[i] = data[i] - 2
      i += 1
    end

    p = 0
    version = data[p]
    p += 1
    if version != SERIALIZED_VERSION
      reason = sprintf format("Could not deserialize ATN with version %d (expected %d).\n", version, SERIALIZED_VERSION)
      raise UnsupportedOperationException, reason
    end

    uuid = to_uuid(data, p)
    p += 8
    unless @@supported_uuids.include?(uuid)
      reason = sprintf format("Could not deserialize ATN with Uuid %s (expected %s or a legacy Uuid).\n", uuid, @@serialized_uuid)
      raise UnsupportedOperationException, reason
    end

    supports_precedence_predicates = feature_supported?(@@added_precedence_transitions, uuid)
    supports_lexer_actions = feature_supported?(@@added_lexer_actions, uuid)

    grammar_type = ATNType::VALUES[data[p]]
    p += 1
    max_token_type = data[p]
    p += 1
    atn = ATN.new(grammar_type, max_token_type)

    loop_back_state_numbers = []
    end_state_numbers = []
    n_states = data[p]
    p += 1
    i = 0
    while i < n_states
      s_type = data[p]
      p += 1
      if s_type == ATNState::INVALID_TYPE
        atn.add_state(nil)
        i += 1
        next
      end

      rule_index = data[p]
      p += 1
      rule_index = -1 if rule_index == 0xFFFF

      s = state_factory(s_type, rule_index)
      if s_type == ATNState::LOOP_END
        loop_back_state_number = data[p]
        p += 1
        pair = OpenStruct.new
        pair.a = s
        pair.b = loop_back_state_number
        loop_back_state_numbers << pair
      elsif s.is_a? BlockStartState
        end_state_number = data[p]
        p += 1
        pair = OpenStruct.new
        pair.a = s
        pair.b = end_state_number
        end_state_numbers << pair
      end
      atn.add_state(s)
      i += 1
    end

    loop_back_state_numbers.each do |pair|
      pair.a.loopback_state = atn.states[pair.b]
    end

    end_state_numbers.each do |pair|
      pair.a.end_state = atn.states[pair.b]
    end

    num_non_greedy_states = data[p]
    p += 1
    i = 0
    while i < num_non_greedy_states
      state_number = data[p]
      p += 1
      atn.states[state_number].non_greedy = true
      i += 1
    end

    if supports_precedence_predicates
      num_precedence_states = data[p]
      p += 1
      i = 0
      while i < num_precedence_states
        state_number = data[p]
        p += 1
        atn.states[state_number].is_left_recursive_rule = true
        i += 1
      end
    end

    nrules = data[p]
    p += 1
    atn.rule_to_token_type = [] if atn.grammar_type == ATNType::LEXER

    atn.rule_to_start_state = []
    i = 0
    while i < nrules
      s = data[p]
      p += 1
      start_state = atn.states[s]
      atn.rule_to_start_state[i] = start_state
      if atn.grammar_type == ATNType::LEXER
        token_type = data[p]
        p += 1
        token_type = Token::EOF if token_type == 0xFFFF

        atn.rule_to_token_type[i] = token_type

        unless feature_supported?(@@added_lexer_actions, uuid)
          @action_index_ignored = data[p]
          p += 1
        end
      end
      i += 1
    end

    atn.rule_to_stop_state = []
    atn.states.each do |state|
      next unless state.is_a? RuleStopState

      stop_state = state
      atn.rule_to_stop_state[state.rule_index] = stop_state
      atn.rule_to_start_state[state.rule_index].stop_state = stop_state
    end

    n_modes = data[p]
    p += 1
    i = 0
    while i < n_modes
      s = data[p]
      p += 1
      atn.mode_to_start_state << atn.states[s]
      i += 1
    end

    sets = []

    p = deserialize_sets(data, p, sets, ATNDeserializer.unicode_deserializer(UnicodeDeserializingMode::UNICODE_BMP))

    if feature_supported?(@@added_unicode_smp, uuid)
      p = deserialize_sets(data, p, sets, ATNDeserializer.unicode_deserializer(UnicodeDeserializingMode::UNICODE_SMP))
    end

    n_edges = data[p]
    p += 1
    i = 0
    while i < n_edges
      src = data[p]
      trg = data[p + 1]
      ttype = data[p + 2]
      arg1 = data[p + 3]
      arg2 = data[p + 4]
      arg3 = data[p + 5]
      trans = edge_factory(atn, ttype, src, trg, arg1, arg2, arg3, sets)
      src_state = atn.states[src]
      src_state.add_transition(trans)
      p += 6
      i += 1
    end

    atn.states.each do |state|
      i = 0
      while i < state.number_of_transitions
        t = state.transition(i)
        unless t.is_a? RuleTransition
          i += 1
          next
        end

        rule_transition = t
        outermost_precedence_return = -1
        if atn.rule_to_start_state[rule_transition.target.rule_index].is_left_recursive_rule
          if rule_transition.precedence == 0
            outermost_precedence_return = rule_transition.target.rule_index
          end
        end

        return_transition = EpsilonTransition.new(rule_transition.follow_state, outermost_precedence_return)
        atn.rule_to_stop_state[rule_transition.target.rule_index].add_transition(return_transition)
        i += 1
      end
    end

    atn.states.each do |state|
      if state.is_a? BlockStartState
        raise IllegalStateException if state.end_state.nil?

        raise IllegalStateException unless state.end_state.start_state.nil?

        state.end_state.start_state = state
      end

      if state.is_a? PlusLoopbackState
        loopback_state = state
        i = 0
        while i < loopback_state.number_of_transitions
          target = loopback_state.transition(i).target
          if target.is_a? PlusBlockStartState
            target.loopback_state = loopback_state
          end
          i += 1
        end
      elsif state.is_a? StarLoopbackState
        loopback_state = state
        i = 0
        while i < loopback_state.number_of_transitions
          target = loopback_state.transition(i).target
          if target.is_a? StarLoopEntryState
            target.loopback_state = loopback_state
          end
          i += 1
        end
      end
    end

    n_decisions = data[p]
    p += 1
    i = 1
    while i <= n_decisions
      s = data[p]
      p += 1
      dec_state = atn.states[s]
      atn.decision_to_state << dec_state
      dec_state.decision = i - 1
      i += 1
    end

    if atn.grammar_type == ATNType::LEXER
      if supports_lexer_actions
        atn._a = Array.new(data[p])
        p += 1
        i = 0
        while i < atn._a.length
          action_type = data[p]
          p += 1
          data1 = data[p]
          p += 1
          data1 = -1 if data1 == 0xFFFF

          data2 = data[p]
          p += 1
          data2 = -1 if data2 == 0xFFFF

          lexer_action = lexer_action_factory(action_type, data1, data2)

          atn._a[i] = lexer_action
          i += 1
        end
      else
        legacy_lexer_actions = []
        atn.states.each do |state|
          i = 0
          while i < state.number_of_transitions
            transition = state.transition(i)
            next unless transition.is_a? ActionTransition

            rule_index = transition.rule_index
            action_index = transition.action_index
            lexer_action = LexerCustomAction.new(rule_index, action_index)
            state.set_transition(i, ActionTransition.new(transition.target, rule_index, legacy_lexer_actions.length, false))
            legacy_lexer_actions << lexer_action
            i += 1
          end
        end

        atn._a = legacy_lexer_actions
      end
    end

    mark_precedence_decisions(atn)

    verify_atn(atn) if @deserialization_options.verify_atn?

    if @deserialization_options.generate_rule_bypass_transitions? && atn.grammar_type == ATNType.PARSER
      atn.rule_to_token_type = []
      i = 0
      while i < atn.rule_to_start_state.length
        atn.rule_to_token_type[i] = atn.max_token_type + i + 1
        i += 1
      end

      i = 0
      while i < atn.rule_to_start_state.length
        bypass_start = BasicBlockStartState.new
        bypass_start.rule_index = i
        atn.add_state(bypass_start)

        bypass_stop = BlockEndState.new
        bypass_stop.rule_index = i
        atn.add_state(bypass_stop)

        bypass_start.end_state = bypass_stop
        atn.define_decision_state(bypass_start)

        bypass_stop.start_state = bypass_start

        exclude_transition = nil
        if atn.rule_to_start_state[i].is_left_recursive_rule
          end_state = nil
          atn.states.each do |state|
            next if state.rule_index != i

            next unless state.is_a? StarLoopEntryState

            maybe_loop_end_state = state.transition(state.number_of_transitions - 1).target
            next unless maybe_loop_end_state.is_a? LoopEndState

            if maybe_loop_end_state.epsilon_only_transitions && maybe_loop_end_state.transition(0).target.is_a?(RuleStopState)
              end_state = state
              break
            end
          end

          if end_state.nil?
            raise UnsupportedOperationException, "Couldn't identify final state of the precedence rule prefix section."
          end

          exclude_transition = end_state.loopback_state.transition(0)
        else
          end_state = atn.rule_to_stop_state[i]
        end

        atn.states.each do |state|
          state.transitions.each do |transition|
            next if transition == exclude_transition

            transition.target = bypass_stop if transition.target == end_state
          end
        end

        while atn.rule_to_start_state[i].number_of_transitions > 0
          transition = atn.rule_to_start_state[i].remove_transition(atn.rule_to_start_state[i].number_of_transitions - 1)
          bypass_start.add_transition(transition)
        end

        atn.rule_to_start_state[i].add_transition(new(EpsilonTransition(bypass_start)))
        bypass_stop.add_transition(new(EpsilonTransition(end_state)))

        match_state = BasicState.new
        atn.add_state(match_state)
        match_state.add_transition(AtomTransition.new(bypass_stop, atn.rule_to_token_type[i]))
        bypass_start.add_transition(EpsilonTransition.new(match_state))
      end

      verify_atn(atn) if deserializationOptions.verify_atn?
    end

    atn
  end

  def deserialize_sets(data, p, sets, unicode_deserializer)
    n_sets = data[p]
    p += 1
    i = 0
    while i < n_sets
      n_intervals = data[p]
      p += 1
      set = IntervalSet.new
      sets << set

      contains_eof = data[p] != 0
      p += 1
      set.add(-1) if contains_eof

      j = 0
      while j < n_intervals
        a = unicode_deserializer.read_unicode(data, p)
        p += unicode_deserializer.size
        b = unicode_deserializer.read_unicode(data, p)
        p += unicode_deserializer.size
        set.add(a, b)
        j += 1
      end
      i += 1
    end
    p
  end

  def mark_precedence_decisions(atn)
    atn.states.each do |state|
      next unless state.is_a? StarLoopEntryState

      next unless atn.rule_to_start_state[state.rule_index].is_left_recursive_rule

      maybeLoopEndState = state.transition(state.number_of_transitions - 1).target
      next unless maybeLoopEndState.is_a? LoopEndState

      if maybeLoopEndState.epsilon_only_transitions && maybeLoopEndState.transition(0).target.is_a?(RuleStopState)
        state.is_precedence_pecision = true
      end
    end
  end

  def verify_atn(atn)
    atn.states.each do |state|
      next if state.nil?

      check_condition(state.only_has_epsilon_transitions || state.number_of_transitions <= 1)

      if state.is_a? PlusBlockStartState
        check_condition(!state.loopback_state.nil?)
      end

      if state.is_a? StarLoopEntryState
        star_loop_entry_state = state
        check_condition(!star_loop_entry_state.loopback_state.nil?)
        check_condition(star_loop_entry_state.number_of_transitions == 2)

        if star_loop_entry_state.transition(0).target.is_a? StarBlockStartState
          check_condition(star_loop_entry_state.transition(1).target.is_a?(LoopEndState))
          check_condition(!star_loop_entry_state.non_greedy)
        elsif star_loop_entry_state.transition(0).target.is_a? LoopEndState
          check_condition(star_loop_entry_state.transition(1).target.is_a?(StarBlockStartState))
          check_condition(star_loop_entry_state.non_greedy)
        else
          raise IllegalStateException
        end
      end

      if state.is_a? StarLoopbackState
        check_condition(state.number_of_transitions == 1)
        check_condition(state.transition(0).target.is_a?(StarLoopEntryState))
      end

      check_condition(!state.loopback_state.nil?) if state.is_a? LoopEndState

      check_condition(!state.stop_state.nil?) if state.is_a? RuleStartState

      check_condition(!state.end_state.nil?) if state.is_a? BlockStartState

      check_condition(!state.start_state.nil?) if state.is_a? BlockEndState

      if state.is_a? DecisionState
        decision_state = state
        check_condition(decision_state.number_of_transitions <= 1 || decision_state.decision >= 0)
      else
        check_condition(state.number_of_transitions <= 1 || state.is_a?(RuleStopState))
      end
    end
  end

  def check_condition(condition, message = nil)
    raise IllegalStateException, message unless condition
  end

  def to_int32(data, offset)
    data[offset] | (data[offset + 1] << 16)
  end

  def to_long(data, offset)
    low_order = to_int32(data, offset) & 0x00000000FFFFFFFF
    low_order | (to_int32(data, offset + 2) << 32)
  end

  def to_uuid(data, offset)
    least_sig_bits = to_long(data, offset)
    mostSigBits = to_long(data, offset + 4)
    UUID.new(mostSigBits, least_sig_bits)
  end

  def edge_factory(atn, type, _src, trg, arg1, arg2, arg3, sets)
    target = atn.states[trg]
    case type
    when Transition::EPSILON
      return EpsilonTransition.new(target)
    when Transition::RANGE
      if arg3 != 0
        return RangeTransition.new(target, Token::EOF, arg2)
      else
        return RangeTransition.new(target, arg1, arg2)
      end
    when Transition::RULE
      rt = RuleTransition.new(atn.states[arg1], arg2, arg3, target)
      return rt
    when Transition::PREDICATE
      pt = PredicateTransition.new(target, arg1, arg2, arg3 != 0)
      return pt
    when Transition::PRECEDENCE
      return PrecedencePredicateTransition.new(target, arg1)
    when Transition::ATOM
      if arg3 != 0
        return AtomTransition.new(target, Token::EOF)
      else
        return AtomTransition.new(target, arg1)
      end
    when Transition::ACTION
      a = ActionTransition.new(target, arg1, arg2, arg3 != 0)
      return a
    when Transition::SET
      return SetTransition.new(target, sets[arg1])
    when Transition::NOT_SET
      return NotSetTransition.new(target, sets[arg1])
    when Transition::WILDCARD
      return WildcardTransition.new(target)
    else
      raise IllegalArgumentException, ' The specified transition type is not valid.'
    end
  end

  def state_factory(type, rule_index)
    case type
    when ATNState::INVALID_TYPE
      return nil
    when ATNState::BASIC
      s = BasicState.new
    when ATNState::RULE_START
      s = RuleStartState.new
    when ATNState::BLOCK_START
      s = BasicBlockStartState.new
    when ATNState::PLUS_BLOCK_START
      s = PlusBlockStartState.new
    when ATNState::STAR_BLOCK_START
      s = StarBlockStartState.new
    when ATNState::TOKEN_START
      s = TokensStartState.new
    when ATNState::RULE_STOP
      s = RuleStopState.new
    when ATNState::BLOCK_END
      s = BlockEndState.new
    when ATNState::STAR_LOOP_BACK
      s = StarLoopbackState.new
    when ATNState::STAR_LOOP_ENTRY
      s = StarLoopEntryState.new
    when ATNState::PLUS_LOOP_BACK
      s = PlusLoopbackState.new
    when ATNState::LOOP_END
      s = LoopEndState.new
    else
      message = sprintf format(" The specified state type % d is not valid.\n", type)
      raise IllegalArgumentException, message
    end
    s.rule_index = rule_index
    s
  end

  def lexer_action_factory(type, data1, data2)
    case type
    when LexerActionType::CHANNEL
      LexerChannelAction.new(data1)

    when LexerActionType::CUSTOM
      LexerCustomAction.new(data1, data2)

    when LexerActionType::MODE
      LexerModeAction.new(data1)

    when LexerActionType::MORE
      LexerMoreAction.instance

    when LexerActionType::POP_MODE
      LexerPopModeAction.instance

    when LexerActionType::PUSH_MODE
      LexerPushModeAction.new(data1)

    when LexerActionType::SKIP
      LexerSkipAction.instance

    when LexerActionType::TYPE
      LexerTypeAction.new(data1)

    else
      message = sprintf format(" The specified lexer action type % d is not valid.\n", type)
      raise IllegalArgumentException, message
    end
  end
end
