require 'spec_helper'
require './rush'

describe 'Rush' do
  describe '#parse' do
    subject { parse string }

    context 'just symbol' do
      let(:string) { "(hoge)" }

      it { is_expected.to eq [:hoge] }
    end

    context 'symbol & integer' do
      let(:string) { "(hoge (10))" }

      it { is_expected.to eq [:hoge, [10]] }
    end

    context 'symbol & integer & float' do
      let(:string) { "(hoge (10) 10.5)" }

      it { is_expected.to eq [:hoge, [10], 10.5] }
    end

    context 'like normal calculation' do
      let(:string) { "(+ 10 12 (* -5.5 8))" }

      it { is_expected.to eq [:+, 10, 12, [:*, -5.5, 8]] }
    end
  end

  describe '#parse (alias)' do
    subject { parse string }

    context do
      let(:string) { "(print (+ 10 12 (* -5.5 8)))" }

      it { is_expected.to eq [:print, [:+, 10, 12, [:*, -5.5, 8]]] }
    end
  end

  describe '#tokenize' do
    subject { tokenize string }

    context 'normal input' do
      let(:string) { '(hoge)' }

      it { is_expected.to eq ['(', 'hoge', ')'] }
    end

    context 'input with extra spaces' do
      let(:string) { '( hoge )' }

      it { is_expected.to eq ['(', 'hoge', ')'] }
    end

    context 'many ( & ), and extra spaces' do
      let(:string) { '( (haskell)((     (( () ruby' }

      it { is_expected.to eq ['(', '(', 'haskell', ')', '(', '(', '(', '(', '(', ')', 'ruby'] }
    end

    context 'other symbols' do
      let(:string) { ':^@$"%^' }

      it { is_expected.to eq [':^@$"%^' ] }
    end
  end

  describe '#read_tokens' do
    subject { read_tokens tokens }

    context 'just "(" and ")"' do
      let(:tokens) { ['(', ')'] }

      it { is_expected.to eq [] }
    end

    context '"(" and something and ")"' do
      let(:tokens) { ['(', '100', '3.14', 'hoge', '$%@&^', ')'] }

      it { is_expected.to eq [100, 3.14, :hoge, :"$%@&^"] }
    end

    context 'complex tokens' do
      let(:tokens) { ['(', '(', '100', ')', '(', 'ruby', '(', 'neko', ')', ')', '3.14', ')', 'ignored'] }

      it { is_expected.to eq [[100], [:ruby, [:neko]], 3.14] }
    end

    context 'raise Syntax Error' do
      context 'length == 0' do
        let(:tokens) { [] }

        it { expect { subject }.to raise_error(SyntaxError, "unexpected EOF while reading") }
      end

      context 'tokens just have "("' do
        let(:tokens) { [')'] }

        it { expect { subject }.to raise_error(SyntaxError, 'unexpected ")"') }
      end

      context 'tokens start ")"' do
        let(:tokens) { [')', '(', 'hoge', ')', ')'] }

        it { expect { subject }.to raise_error(SyntaxError, 'unexpected ")"') }
      end

      context 'start from "(" but not end with ")"' do
        let(:tokens) { ['(', 'hoge', 'fuga', '210'] }

        it { expect { subject }.to raise_error(SyntaxError, "unexpected EOF while reading") }
      end
    end
  end

  describe '#static_analysis' do
    subject { static_analysis(tokens, level) }

    context 'given level equal 0' do
      let(:level) { 0 }

      context do
        let(:tokens) { ['('] }

        it { is_expected.to eq 1 }
      end

      context do
        let(:tokens) { ['(', '2', ')'] }

        it { is_expected.to eq 0 }
      end

      context do
        let(:tokens) { ['(', '2', '(', ')'] }

        it { is_expected.to eq 1 }
      end

      context '' do
        let(:tokens) { ['(', '(', '2', ')', ')'] }

        it { is_expected.to eq 0 }
      end
    end
  end

  describe '#atom' do
    subject { atom token }

    context 'Integer' do
      context 'positive' do
        let(:token) { '10' }

        it { is_expected.to eq 10 }
      end

      context 'negative' do
        let(:token) { '-65536' }

        it { is_expected.to eq (-65536) }
      end
    end

    context 'Float' do
      context 'positive' do
        let(:token) { '10.37465' }

        it { is_expected.to eq 10.37465 }
      end

      context 'negative' do
        let(:token) { '-172.367' }

        it { is_expected.to eq (-172.367) }
      end
    end

    context 'Symbol' do
      context 'normal literals' do
        let(:token) { 'hoge' }

        it { is_expected.to eq :hoge }
      end

      context 'other symbols' do
        let(:token) { '$%@*$^' }

        it { is_expected.to eq :"$%@*$^" }
      end
    end
  end

  describe '#evaluate' do
    subject { evaluate exps }

    context 'just a Symbol' do
      let(:exps) { :hoge }

      it { expect { subject }.to raise_error(NoMethodError) }
    end

    context 'Single Depth Array calculation' do
      let(:exps) { [:+, 1, 2] }

      it { is_expected.to eq 3 }
    end

    context 'Multi Depth Array calculation' do
      let(:exps) { [:+, 1, [:*, 5, 10]] }

      it { is_expected.to eq 51 }
    end

    context 'cons' do
      let(:exps) { [:cons, 2, [:*, 5, 10]] }

      it { is_expected.to eq [2, 50] }
    end

    context 'car, cdr' do
      let(:exps) { [:car, [:cons, 99, 2.5]] }

      it { is_expected.to eq 99 }
    end

    context 'list' do
      let(:exps) { [:list, 1, 2, 3] }

      it { is_expected.to eq [1, 2, 3] }
    end

    context 'null?' do
      let(:exps) { [:null?, [:list]] }

      it { is_expected.to eq true }
    end

    context 'symbol?' do
      let(:exps) { [:symbol?, 3] }

      it { is_expected.to eq false }
    end

    context 'define, set!' do
      it do
        evaluate [:define, :hoge, 10]
        expect(evaluate(:hoge)).to eq 10

        evaluate [:set!, :hoge, 65536]
        expect(evaluate(:hoge)).to eq 65536
      end
    end

    context 'lambda' do
      it do
        evaluate [:define, :square, [:lambda, [:n], [:*, :n, :n]]]

        expect(evaluate([:square, 256])).to eq 65536
      end
    end

    context 'quote' do
      let(:exps) { [:quote, [1, 2, [:*, 3.7, 10]]] }

      it { is_expected.to eq [1, 2, [:*, 3.7, 10]] }
    end

    context 'if' do
      let(:exps) { [:if, [:<, 10, 3], 5, 15] }

      it { is_expected.to eq 15 }
    end
  end

  describe '#interpret_once' do
    subject { interpret_once input }

    context do
      let(:input) { '(if (list? (list 1 2 3)) (+ 1 2) (* 8 99))' }

      it { is_expected.to eq 3 }
    end
  end
end
