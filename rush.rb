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
def evaluate(x, env=$GLOBAL_ENV)
  case x
  when Symbol
    begin
      # look for $GLOBAL_ENV hash type data
      # and it would find accurate Proc onject
      env.find(x)[x]
    # ここで rescue しちゃってるけどいいのだろうか
    rescue NoMethodError
      x
    end
  when Array
    case x.first
    when :quote
      _, expr = x
      expr
    when :if
      _, cond, if_t, if_f = x
      evaluate((evaluate(cond, env) ? if_t : if_f), env)
    when :define
      _, var, expr = x
      env[var] = evaluate(expr, env)
      nil
    when :set!
      _, var, expr = x
      env.find(var)[var] = evaluate(expr, env)
    # なんかうまく動かない、式関係なくただ変数の値を評価したものが返却される
    # lambda { |x| x } とおなじ挙動な気がする
    when :lambda
      _, vars, l_expr = x
      lambda { |*args| evaluate(l_expr, Env.new(vars, args, env)) }
    else
      # evaluate recursively
      process, *exps = x.inject([]) {|mem, exp| mem << evaluate(exp, env) }

      # この評価構造が元凶かも(inject だから引数 2 つずつ評価していっちゃう)
      # evaluation
      exps.inject {|m, a| process.call(m, a) }
    end
  else
    x
  end
end

# this class express which scope program is in
class Env < Hash
  def initialize(params=[], args=[], outer=nil)
    hash = Hash[params.zip(args)]
    self.merge!(hash)

    @outer = outer
  end

  # このメソッドあってるのかわからん
  def find(key)
    self.has_key?(key) ? self : @outer.find(key)
  end
end

def make_global_env(env)
  env.merge!({
  :+ => lambda {|x, y| x + y },
  :- => lambda {|x, y| x - y },
  :* => lambda {|x, y| x * y },
  :/ => lambda {|x, y| x / y },
  :not => lambda {|x| !x },
  :< => lambda {|x, y| x < y },
  :> => lambda {|x, y| x > y },
  :<= => lambda {|x, y| x <= y },
  :>= => lambda {|x, y| x >= y },
  :"=" => lambda {|x, y| x == y },
  :cons => lambda {|x, y| [x, y] },
  # ここから下がうまくうごかない
  :car => lambda {|x| x[0] },
  :cdr => lambda {|x| x[1..-1] },
  :list => lambda {|*x| [*x] },
  :list? => lambda {|x| x.is_a?(Array) },
  :null? => lambda {|x| x.empty? },
  :symbol? => lambda {|x| x.is_a?(Symbol) },
  })
end

# Define Global env
$GLOBAL_ENV = make_global_env(Env.new)

if __FILE__ == $0
  interpreter
end
