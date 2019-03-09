class Utils
  def self.num_non_nil(data)
    n = 0
    return n if data.nil?

    data.each do |o|
      n += 1 unless o.nil?
    end
    n
  end

  def self.remove_all_elements(data, value)
    return if data.nil?

    data.remove(value) while data.contains(value)
  end

  def self.escape_whitespace(s, escape_spaces)
    buf = ''
    s.each_char do |c|
      buf << if c == ' ' && escape_spaces
               '\u00B7'
             elsif c == '\t'
               '\\t'
             elsif c == '\n'
               '\\n'
             elsif c == '\r'
               '\\r'
             else
               c
             end
    end
    buf
  end

  def self.write_file(file_name, content, _encoding = nil)
    f = File.new(file_name, 'w')

    begin
      f << content
    ensure
      f.close
    end
  end

  def self.read_file(file_name, _encoding = nil)
    f = File.new(file_name, 'r')
    size = File.size(file_name)

    begin
      data = Array.new(size)
      f.read(nil, data)
    ensure
      f.close
    end

    data
  end

  def self.expand_tabs(s, tab_size)
    return nil if s.nil?

    buf = ''
    col = 0
    i = 0
    while i < s.length
      c = s[i]
      case c
      when '\n'
        col = 0
        buf << c
      when '\t'
        n = tab_size - col % tab_size
        col += n
        buf << spaces(n)
      else
        col += 1
        buf << c
      end
      i += 1
    end
    buf
  end

  def self.spaces(n)
    sequence(n, ' ')
  end

  def self.newlines(n)
    sequence(n, "\n")
  end

  def self.sequence(n, s)
    buf = ''
    sp = 1
    while sp <= n
      buf << s
      sp += 1
    end
    buf
  end

  def self.count(s, x)
    n = 0
    i = 0
    while i < s.length
      n += 1 if s[i] == x
      i += 1
    end
    n
  end
end
