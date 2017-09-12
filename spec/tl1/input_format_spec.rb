# frozen_string_literal: true
require 'spec_helper'

module TL1
  describe InputFormat do
    describe '#format' do
      it 'constructs an input message with given variables' do
        source = 'RTRV-EQPT:<tid1>,<tid2:<aid>:C1=<custom1>,C2=<custom2>'
        format = InputFormat.new(source)
        message = format.format(aid: 'MS-1', tid1: 'first', custom2: 'second')
        expect(message).to eq 'RTRV-EQPT:first,:MS-1:C2=second'
      end
    end # describe '#format' do
  end # describe InputFormat do
end # module TL1
