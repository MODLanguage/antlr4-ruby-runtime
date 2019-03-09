require '../antlr4/interval_set'

class ATNState
  INITIAL_NUM_TRANSITIONS = 4
  INVALID_TYPE = 0
  BASIC = 1
  RULE_START = 2
  BLOCK_START = 3
  PLUS_BLOCK_START = 4
  STAR_BLOCK_START = 5
  TOKEN_START = 6
  RULE_STOP = 7
  BLOCK_END = 8
  STAR_LOOP_BACK = 9
  STAR_LOOP_ENTRY = 10
  PLUS_LOOP_BACK = 11
  LOOP_END = 12

  @@serialization_names = %w[INVALID BASIC RULE_START BLOCK_START PLUS_BLOCK_START STAR_BLOCK_START TOKEN_START RULE_STOP BLOCK_END STAR_LOOP_BACK STAR_LOOP_ENTRY PLUS_LOOP_BACK LOOP_END]

  @@invalid_state_number = -1

  class << self
    attr_accessor :invalid_state_number
  end

  attr_accessor :next_token_within_rule
  attr_accessor :atn
  attr_accessor :state_number
  attr_accessor :rule_index

  def initialize
    @atn = nil
    @state_number = @@invalid_state_number
    @rule_index = 0
    @epsilon_only_transitions = false
    @transitions = []
    @next_token_within_rule = nil
  end

  def hash
    @state_number
  end

  def eql?(other_key)
    @state_number == other_key.state_number
  end

  def non_greedy_exit_state?
    false
  end

  def to_s
    @state_number.to_s
  end

  attr_reader :transitions

  def number_of_transitions
    @transitions.length
  end

  def add_transition(e)
    add_transition_at(@transitions.length, e)
  end

  def add_transition_at(index, e)
    if @transitions.empty?

      @epsilon_only_transitions = e.epsilon?

    elsif @epsilon_only_transitions != e.epsilon?

      STDERR.puts format("ATN state %d has both epsilon and non-epsilon transitions.\n", state_number)
      @epsilon_only_transitions = false
    end
    already_present = false

    @transitions.each do |t|
      if t.target.state_number == e.target.state_number

        if !t.label.nil? && !e.label.nil? && t.label.eql?(e.label)
          already_present = true
          break
        elsif t.epsilon? && e.epsilon?
          already_present = true
          break
        end
      end
    end

    @transitions[index] = e unless already_present
  end

  def transition(i)
    @transitions[i]
  end

  def set_transition(i, e)
    @transitions[i] = e
  end

  def remove_transition(index)
    @transitions.delete_at index
  end

  def only_has_epsilon_transitions
    @epsilon_only_transitions
  end

  def set_rule_index(rule_index)
    @rule_index = rule_index
  end
end
