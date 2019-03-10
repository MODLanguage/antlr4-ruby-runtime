require 'set'
require 'singleton'
require 'ostruct'
require 'weakref'

module Antlr4
  module Runtime
  end
end

require 'antlr4/runtime/char_streams'
require 'antlr4/runtime/common_token_stream'
require 'antlr4/runtime/prediction_context_cache'
require 'antlr4/runtime/vocabulary_impl'
require 'antlr4/runtime/dfa'
require 'antlr4/runtime/atn_deserializer'
require 'antlr4/runtime/lexer_atn_simulator'
require 'antlr4/runtime/parser_atn_simulator'
require 'antlr4/runtime/parser_rule_context'
require 'antlr4/runtime/lexer'
require 'antlr4/runtime/parser'
require 'antlr4/runtime/parse_tree_listener'
require 'antlr4/runtime/parse_tree_visitor'
require 'antlr4/runtime/abstract_parse_tree_visitor'
