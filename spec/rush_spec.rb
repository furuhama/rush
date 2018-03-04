require 'spec_helper'
require './rush'

describe 'Rush' do
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

    context 'many ( & )' do
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

    context 'length == 0' do
      let(:tokens) { [] }
      it { expect { subject }.to raise_error(SyntaxError) }
    end

    context 'tokens just have "("' do
      let(:tokens) { [')'] }
      it { expect { subject }.to raise_error(SyntaxError) }
    end

    context 'tokens start ")"' do
      let(:tokens) { [')', '(', 'hoge', ')', ')'] }
      it { expect { subject }.to raise_error(SyntaxError) }
    end
  end
end
