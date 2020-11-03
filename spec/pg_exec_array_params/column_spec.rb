# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PgExecArrayParams::Column do
  describe '.from_res_target' do
    let(:res_target) { [] }
    subject { described_class.from_res_target(res_target) }

    context 'with expressions' do
      let(:res_target) { parse_res_target('select 1 + 1') }
      it { is_expected.to be_nil }
    end

    context 'with constants' do
      let(:res_target) { parse_res_target('select 1') }
      it { is_expected.to be_nil }
    end

    context 'with simple field' do
      let(:res_target) { parse_res_target('select x') }
      its(:name) { is_expected.to eq 'x' }
    end

    context 'with aliased field' do
      let(:res_target) { parse_res_target('select x as y') }
      its(:name) { is_expected.to eq 'y' }
    end

    context 'with simple field and table name' do
      let(:res_target) { parse_res_target('select z.x') }
      its(:name) { is_expected.to eq 'x' }
    end

    context 'with aliased field and table name' do
      let(:res_target) { parse_res_target('select z.x as y') }
      its(:name) { is_expected.to eq 'y' }
    end
  end
end
