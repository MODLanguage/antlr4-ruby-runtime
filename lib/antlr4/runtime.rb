require 'set'
require 'singleton'
require 'ostruct'
require 'weakref'

require 'rumourhash/rumourhash'

module Antlr4
  module Runtime
    autoload :AbstractParseTreeVisitor, 'antlr4/runtime/abstract_parse_tree_visitor'
    autoload :AbstractPredicateTransition, 'antlr4/runtime/abstract_predicate_transition'
    autoload :ActionTransition, 'antlr4/runtime/action_transition'
    autoload :AmbiguityInfo, 'antlr4/runtime/ambiguity_info'
    autoload :ANTLRErrorListener, 'antlr4/runtime/antlr_error_listener'
    autoload :ANTLRErrorStrategy, 'antlr4/runtime/antlr_error_strategy'
    autoload :ANTLRFileStream, 'antlr4/runtime/antlr_file_stream'
    autoload :ANTLRInputStream, 'antlr4/runtime/antlr_input_stream'
    autoload :Array2DHashSet, 'antlr4/runtime/array_2d_hash_set'
    autoload :ArrayPredictionContext, 'antlr4/runtime/array_prediction_context'
    autoload :ATN, 'antlr4/runtime/atn'
    autoload :ATNConfig, 'antlr4/runtime/atn_config'
    autoload :ATNConfigSet, 'antlr4/runtime/atn_config_set'
    autoload :ATNDeserializationOptions, 'antlr4/runtime/atn_deserialization_options'
    autoload :ATNDeserializer, 'antlr4/runtime/atn_deserializer'
    autoload :ATNSimulator, 'antlr4/runtime/atn_simulator'
    autoload :ATNState, 'antlr4/runtime/atn_state'
    autoload :ATNType, 'antlr4/runtime/atn_type'
    autoload :AtomTransition, 'antlr4/runtime/atom_transition'
    autoload :BailErrorStrategy, 'antlr4/runtime/bail_error_strategy'
    autoload :BaseErrorListener, 'antlr4/runtime/base_error_listener'
    autoload :BasicBlockStartState, 'antlr4/runtime/basic_block_start_state'
    autoload :BasicState, 'antlr4/runtime/basic_state'
    autoload :BitSet, 'antlr4/runtime/bit_set'
    autoload :BlockEndState, 'antlr4/runtime/block_end_state'
    autoload :BlockStartState, 'antlr4/runtime/block_start_state'
    autoload :BufferedTokenStream, 'antlr4/runtime/buffered_token_stream'
    autoload :CharStream, 'antlr4/runtime/char_stream'
    autoload :CharStreams, 'antlr4/runtime/char_streams'
    autoload :CodePointCharStream, 'antlr4/runtime/code_point_char_stream'
    autoload :CommonToken, 'antlr4/runtime/common_token'
    autoload :CommonTokenFactory, 'antlr4/runtime/common_token_factory'
    autoload :CommonTokenStream, 'antlr4/runtime/common_token_stream'
    autoload :ConsoleErrorListener, 'antlr4/runtime/console_error_listener'
    autoload :ContextSensitivityInfo, 'antlr4/runtime/context_sensitivity_info'
    autoload :DecisionEventInfo, 'antlr4/runtime/decision_event_info'
    autoload :DecisionInfo, 'antlr4/runtime/decision_info'
    autoload :DecisionState, 'antlr4/runtime/decision_state'
    autoload :DefaultErrorStrategy, 'antlr4/runtime/default_error_strategy'
    autoload :DFA, 'antlr4/runtime/dfa'
    autoload :DFASerializer, 'antlr4/runtime/dfa_serializer'
    autoload :DFAState, 'antlr4/runtime/dfa_state'
    autoload :DiagnosticErrorListener, 'antlr4/runtime/diagnostic_error_listener'
    autoload :DoubleKeyMap, 'antlr4/runtime/double_key_map'
    autoload :EmptyPredictionContext, 'antlr4/runtime/empty_prediction_context'
    autoload :EpsilonTransition, 'antlr4/runtime/epsilon_transition'
    autoload :EqualityComparator, 'antlr4/runtime/equality_comparator'
    autoload :ErrorInfo, 'antlr4/runtime/error_info'
    autoload :ErrorNode, 'antlr4/runtime/error_node'
    autoload :ErrorNodeImpl, 'antlr4/runtime/error_node_impl'
    autoload :FailedPredicateException, 'antlr4/runtime/failed_predicate_exception'
    autoload :FlexibleHashMap, 'antlr4/runtime/flexible_hash_map'
    autoload :InputMismatchException, 'antlr4/runtime/input_mismatch_exception'
    autoload :IntStream, 'antlr4/runtime/int_stream'
    autoload :Integer, 'antlr4/runtime/integer'
    autoload :Interval, 'antlr4/runtime/interval'
    autoload :IntervalSet, 'antlr4/runtime/interval_set'
    autoload :Lexer, 'antlr4/runtime/lexer'
    autoload :LexerAction, 'antlr4/runtime/lexer_action'
    autoload :LexerActionExecutor, 'antlr4/runtime/lexer_action_executor'
    autoload :LexerActionType, 'antlr4/runtime/lexer_action_type'
    autoload :LexerATNConfig, 'antlr4/runtime/lexer_atn_config'
    autoload :LexerATNSimulator, 'antlr4/runtime/lexer_atn_simulator'
    autoload :LexerChannelAction, 'antlr4/runtime/lexer_channel_action'
    autoload :LexerCustomAction, 'antlr4/runtime/lexer_custom_action'
    autoload :LexerDfaSerializer, 'antlr4/runtime/lexer_dfa_serializer'
    autoload :LexerIndexedCustomAction, 'antlr4/runtime/lexer_indexed_custom_action'
    autoload :LexerModeAction, 'antlr4/runtime/lexer_mode_action'
    autoload :LexerMoreAction, 'antlr4/runtime/lexer_more_action'
    autoload :LexerNoViableAltException, 'antlr4/runtime/lexer_no_viable_alt_exception'
    autoload :LexerPopModeAction, 'antlr4/runtime/lexer_pop_mode_action'
    autoload :LexerPushModeAction, 'antlr4/runtime/lexer_push_mode_action'
    autoload :LexerSkipAction, 'antlr4/runtime/lexer_skip_action'
    autoload :LexerTypeAction, 'antlr4/runtime/lexer_type_action'
    autoload :LL1Analyzer, 'antlr4/runtime/ll1_analyzer'
    autoload :LookaheadEventInfo, 'antlr4/runtime/lookahead_event_info'
    autoload :LoopEndState, 'antlr4/runtime/loop_end_state'
    autoload :NoViableAltException, 'antlr4/runtime/no_viable_alt_exception'
    autoload :NotSetTransition, 'antlr4/runtime/not_set_transition'
    autoload :ObjectEqualityComparator, 'antlr4/runtime/object_equality_comparator'
    autoload :OrderedATNConfigSet, 'antlr4/runtime/ordered_atn_config_set'
    autoload :ParseCancellationException, 'antlr4/runtime/parse_cancellation_exception'
    autoload :ParseTree, 'antlr4/runtime/parse_tree'
    autoload :ParseTreeListener, 'antlr4/runtime/parse_tree_listener'
    autoload :ParseTreeVisitor, 'antlr4/runtime/parse_tree_visitor'
    autoload :Parser, 'antlr4/runtime/parser'
    autoload :ParserATNSimulator, 'antlr4/runtime/parser_atn_simulator'
    autoload :ParserRuleContext, 'antlr4/runtime/parser_rule_context'
    autoload :PlusBlockStartState, 'antlr4/runtime/plus_block_start_state'
    autoload :PlusLoopbackState, 'antlr4/runtime/plus_loopback_state'
    autoload :PrecedencePredicateTransition, 'antlr4/runtime/precedence_predicate_transition'
    autoload :Predicate, 'antlr4/runtime/predicate'
    autoload :PredicateEvalInfo, 'antlr4/runtime/predicate_eval_info'
    autoload :PredicateTransition, 'antlr4/runtime/predicate_transition'
    autoload :PredictionContext, 'antlr4/runtime/prediction_context'
    autoload :PredictionContextCache, 'antlr4/runtime/prediction_context_cache'
    autoload :PredictionContextUtils, 'antlr4/runtime/prediction_context_utils'
    autoload :PredictionMode, 'antlr4/runtime/prediction_mode'
    autoload :ProfilingATNSimulator, 'antlr4/runtime/profiling_atn_simulator'
    autoload :ProxyErrorListener, 'antlr4/runtime/proxy_error_listener'
    autoload :RangeTransition, 'antlr4/runtime/range_transition'
    autoload :RecognitionException, 'antlr4/runtime/recognition_exception'
    autoload :Recognizer, 'antlr4/runtime/recognizer'
    autoload :RuleContext, 'antlr4/runtime/rule_context'
    autoload :RuleContextWithAltNum, 'antlr4/runtime/rule_context_with_alt_num'
    autoload :RuleNode, 'antlr4/runtime/rule_node'
    autoload :RuleStartState, 'antlr4/runtime/rule_start_state'
    autoload :RuleStopState, 'antlr4/runtime/rule_stop_state'
    autoload :RuleTagToken, 'antlr4/runtime/rule_tag_token'
    autoload :RuleTransition, 'antlr4/runtime/rule_transition'
    autoload :SemanticContext, 'antlr4/runtime/semantic_context'
    autoload :SetTransition, 'antlr4/runtime/set_transition'
    autoload :SingletonPredictionContext, 'antlr4/runtime/singleton_prediction_context'
    autoload :StarBlockStartState, 'antlr4/runtime/star_block_start_state'
    autoload :StarLoopEntryState, 'antlr4/runtime/star_loop_entry_state'
    autoload :StarLoopbackState, 'antlr4/runtime/star_loopback_state'
    autoload :TagChunk, 'antlr4/runtime/tag_chunk'
    autoload :TerminalNode, 'antlr4/runtime/terminal_node'
    autoload :TerminalNodeImpl, 'antlr4/runtime/terminal_node_impl'
    autoload :TextChunk, 'antlr4/runtime/text_chunk'
    autoload :Token, 'antlr4/runtime/token'
    autoload :TokenStream, 'antlr4/runtime/token_stream'
    autoload :TokenTagToken, 'antlr4/runtime/token_tag_token'
    autoload :TokensStartState, 'antlr4/runtime/tokens_start_state'
    autoload :Transition, 'antlr4/runtime/transition'
    autoload :Trees, 'antlr4/runtime/trees'
    autoload :Triple, 'antlr4/runtime/triple'
    autoload :Utils, 'antlr4/runtime/utils'
    autoload :UUID, 'antlr4/runtime/uuid'
    autoload :Version, 'antlr4/runtime/version'
    autoload :Vocabulary, 'antlr4/runtime/vocabulary'
    autoload :VocabularyImpl, 'antlr4/runtime/vocabulary_impl'
    autoload :WildcardTransition, 'antlr4/runtime/wildcard_transition'
    autoload :WritableToken, 'antlr4/runtime/writable_token'
  end
end

module RumourHash

end

module BitCount

end
