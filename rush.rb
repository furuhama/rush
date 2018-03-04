# Rush (= Ruby Scheme Interpreter)

# main function
def interpreter
  loop do
    print 'rush >> '
    input = gets

    # when "quit" is input, break lopp
    break if input == "quit\n"

    print parse(input), "\n"
  end
  print "bye...\n"
end

# tokenize & parse input
def read(s)
  read_tokens tokenize(s)
end
alias :parse :read

# separate input words
def tokenize(s)
  s.gsub(/[()]/, ' \0 ').split
end

# convert tokens into structured Array
def read_tokens(tokens)
  raise SyntaxError, 'unexpected EOF while reading' if tokens.length == 0

  case token = tokens.shift
  when '('
    l = []
    while tokens[0] != ')'
      l.push read_tokens(tokens)
    end
    tokens.shift
    l
  when ')'
    raise SyntaxError, 'unexpected ")"'
  else
    atom token
  end
end

# type casting
def atom(token)
  type_casts = [
    lambda { |arg| Integer arg },
    lambda { |arg| Float arg },
    lambda { |arg| arg.to_sym },
  ]

  begin
    type_casts.first.call(token)
  rescue ArgumentError
    # remove first element of type_casts
    # and retry this method
    type_casts.shift
    retry
  end
end

# evaluation
def evaluate(x, env={})
  case x
  when Symbol
    begin
      env.find(x)[x]
    rescue NoMethodError
      x
    end
  when Array
    # evaluate recursively
    process, *exps = x.inject([]) {|mem, exp| mem << evaluate(exp, env) }

    # evaluation
    # (it is okay only when `process` can be convert to Proc Object)
    exps.inject {|m, x| process.to_proc.call(m, x) }
  else
    x
  end
end

if __FILE__ == $0
  interpreter
end
