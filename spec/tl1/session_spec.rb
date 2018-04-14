# frozen_string_literal: true

require 'spec_helper'
require 'tl1/test_io'

module TL1
  describe Session do
    let(:eqpt_src) {
      '<aid>:<type>:ID=<id>,C1=<custom1>,C2=<custom2>,C3=<custom3>:<pst>,<sst>'
    }

    let(:act_user) { Command.new('ACT-USER::<username>:::<password>', nil) }
    let(:eqpt) { Command.new('RTRV-EQPT', eqpt_src) }
    let(:io) { TestIO.new('RTRV-EQPT;' => eqpt_output) }

    let(:eqpt_output) do
      <<~EOF
        RTRV-EQPT;

           bti7200hoge 17-08-31 16:29:53
        M  100 COMPLD
           "MS-1:BT7A51AR::IS-NR,"
           "SCP-1-1:BT7A20CA::IS-NR,"
           "DCM-1-2:BT7A12JA::IS-NR,"
           "TPR-1-8:BT7A49AA::IS-NR,"
           "TPR-1-9:BT7A49AA::IS-NR,"
           "TPR-1-10:BT7A49AA::IS-NR,"
           "ES-11:BT7A51AR::IS-NR,"
           "TPR-11-1:BT7A49AA::IS-NR,"
           "TPR-11-17:BT7A49AA::IS-NR,"
           "D40MD-0-1:BT7A37AA::,"
           "D40MD-0-2:BT7A37AA::,"
        ;
        BTI7000>
      EOF
    end

    let(:tl1) { TL1::Session.new(io) }

    describe '#raw_cmd' do
      it 'returns the unprocessed output as a string' do
        expect(tl1.raw_cmd('RTRV-EQPT;')).to eq eqpt_output
      end
    end # describe '#raw_cmd' do

    describe '#cmd' do
      it 'returns an array of processed output records' do
        observed = tl1.cmd(eqpt)

        first = { aid: 'MS-1', type: 'BT7A51AR', pst: 'IS-NR', sst: '' }
        last = { aid: 'D40MD-0-2', type: 'BT7A37AA', pst: '', sst: '' }

        expect(observed.first).to eq first
        expect(observed.last).to eq last
        expect(observed.size).to eq 11

        observed.each do |record|
          expect(record.fetch(:sst)).to eq ''
        end
      end

      context 'input format has keyword arguments' do
        let(:username) { 'asdf' }
        let(:password) { 'qwer' }

        let(:io) do
          TestIO.new(
            "ACT-USER::#{username}:::#{password};" => <<~END
              M  100 COMPLD
              ;
            END
          )
        end

        it 'accepts keyword arguments' do
          tl1.cmd(act_user, username: username, password: password)
        end
      end # context 'input format has keyword arguments' do
    end # describe '#cmd' do
  end # describe Session do
end # module TL1
