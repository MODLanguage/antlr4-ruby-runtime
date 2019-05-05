require 'antlr4/runtime/common_token'

module Antlr4::Runtime

  class CommonTokenFactory
    include Singleton

    def initialize(copy_text = false)
      @copy_text = false
      @copy_text = copy_text
    end

    def create(source, type, text, channel, start, stop, line, char_position_in_line)
      t = CommonToken.create1(source, type, channel, start, stop)
      t.line = line
      t.char_position_in_line = char_position_in_line
      if !text.nil?
        t._text = text
      elsif @copy_text && !source.b.nil?
        t.set_text(source.b.text(Interval.of(start, stop)))
      end

      t
    end

    def create_simple(type, text)
      CommonToken.create2(type, text)
    end
  end
end