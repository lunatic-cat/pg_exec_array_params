# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PgExecArrayParams::Query do
  let(:params) { [] }
  subject { described_class.new(query, params) }

  describe '#columns' do
    let(:query) { 'with y as (select * from s) SELECT x, y.y, z.z as z from x join z on z.z = x join y on y.y = x' }

    it 'extracts columns' do
      expect(subject.columns.map(&:name)).to eq %w[x y z]
    end
  end

  describe '#rebuild_query!' do
    let(:query) { 'select * from t1 where a1 = $1 and a2 = $2 and a3 = $3 and a4 = $4' }
    let(:params) { [1, [2, 3], 'foo', %w[bar baz]] }

    let(:sql) { 'SELECT * FROM "t1" WHERE "a1" = $1 AND "a2" IN ($2, $3) AND "a3" = $4 AND "a4" IN ($5, $6)' }

    it 'works', :aggregate_failures do
      expect(subject.sql).to eq sql
      expect(subject.binds).to eq params.flatten
    end
  end
end
