require 'antlr4/runtime/flexible_hash_map'
require 'antlr4/runtime/bit_set'

module Antlr4::Runtime

  class PredictionMode
    SLL = 0
    LL = 1
    LL_EXACT_AMBIG_DETECTION = 2

    class AltAndContextMap < FlexibleHashMap
      def initialize
        super(AltAndContextConfigEqualityComparator.instance)
      end
    end

    class AltAndContextConfigEqualityComparator
      include Singleton

      def hash(o)
        MurmurHash.hash_int_obj(o.state.state_number, o.context)
      end

      def equals(a, b)
        return true if a == b
        return false if a.nil? || b.nil?

        a.state.state_number == b.state.state_number && a.context.eql?(b.context)
      end
    end

    def self.has_sll_conflict_terminating_prediction(mode, configs)
      return true if all_configs_in_rule_stop_states?(configs)

      # pure SLL mode parsing
      if mode == PredictionMode::SLL
        # Don't bother with combining configs from different semantic
        # contexts if we can fail over to full LL costs more time
        # since we'll often fail over anyway.
        if configs.has_semantic_context
          # dup configs, tossing out semantic predicates
          dup = ATNConfigSet.new
          i = 0
          while i < configs.configs.length
            cfg = configs.configs[i]
            c = ATNConfig.new
            c.atn_config5(cfg, SemanticContext::NONE)
            dup.add(c)

            i += 1
          end

          configs = dup
        end
        # now we have combined contexts for configs with dissimilar preds
      end

      # pure SLL or combined SLL+LL mode parsing

      alt_sets = conflicting_alt_subsets(configs)
      heuristic = has_conflicting_alt_set?(alt_sets) && !has_state_associated_with_one_alt?(configs)
      heuristic
    end

    def self.has_config_in_rule_stop_state?(configs)
      i = 0
      while i < configs.configs.length
        return true if configs.configs[i].state.is_a? RuleStopState
        i += 1
      end

      false
    end

    def self.all_configs_in_rule_stop_states?(configs)
      i = 0
      while i < configs.configs.length
        return false unless configs.configs[i].state.is_a? RuleStopState
        i += 1
      end

      true
    end

    def self.resolves_to_just_one_viable_alt?(altsets)
      single_viable_alt(altsets)
    end

    def self.all_subsets_conflict?(altsets)
      !has_non_conflicting_alt_set?(altsets)
    end

    def self.has_non_conflicting_alt_set?(altsets)
      i = 0
      while i < altsets.length
        alts = altsets[i]
        return true if alts.cardinality == 1
        i += 1
      end
      false
    end

    def self.has_conflicting_alt_set?(altsets)
      i = 0
      while i < altsets.length
        alts = altsets[i]
        return true if alts.cardinality > 1
        i += 1
      end
      false
    end

    def all_subsets_equal?(altsets)
      first = nil
      i = 0
      while i < altsets.length
        alt = altsets[i]
        if i == 0
          first = altsets[0]
        else
          return false unless alt.eql?(first)
        end
        i += 1
      end
      true
    end

    def self.unique_alt(altsets)
      all = get_alts1(altsets)
      return all.next_set_bit(0) if all.cardinality == 1

      ATN::INVALID_ALT_NUMBER
    end

    def self.get_alts1(altsets)
      all = BitSet.new
      i = 0
      while i < altsets.length
        alts = altsets[i]
        all.or(alts)
        i += 1
      end
      all
    end

    def get_alts2(configs)
      alts = BitSet.new
      i = 0
      while i < configs.length
        config = configs[i]
        alts.set(config.alt)
        i += 1
      end
      alts
    end

    def self.conflicting_alt_subsets(configs)
      config_to_alts = AltAndContextMap.new
      i = 0
      while i < configs.configs.length
        c = configs.configs[i]
        alts = config_to_alts.get(c)
        if alts.nil?
          alts = BitSet.new
          config_to_alts.put(c, alts)
        end
        alts.set(c.alt)
        i += 1
      end
      config_to_alts.values
    end

    def self.state_to_alt_map(configs)
      m = {}
      i = 0
      while i < configs.configs.length
        c = configs.configs[i]
        alts = m[c.state]
        if alts.nil?
          alts = BitSet.new
          m[c.state] = alts
        end
        alts.set(c.alt)
        i += 1
      end
      m
    end

    def self.has_state_associated_with_one_alt?(configs)
      x = state_to_alt_map(configs)
      i = 0
      while i < x.values.length
        alts = x.values[i]
        return true if alts.cardinality == 1
        i += 1
      end
      false
    end

    def self.single_viable_alt(altsets)
      viable_alts = BitSet.new
      i = 0
      while i < altsets.length
        alts = altsets[i]
        min_alt = alts.next_set_bit(0)
        viable_alts.set(min_alt)
        return ATN::INVALID_ALT_NUMBER if viable_alts.cardinality > 1 # more than 1 viable alt
        i += 1
      end
      viable_alts.next_set_bit(0)
    end
  end
end