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

  RSpec.shared_examples 'builds proper sql & binds' do
    it 'works', :aggregate_failures do
      expect(subject.sql).to eq sql
      expect(subject.binds).to eq params.flatten
    end
  end

  describe '#rebuild_query!' do
    let(:params) { [1, [2, 3], 'foo', %w[bar baz]] }

    context 'when target list' do
      let(:query) { 'select $1, $2, $3' }
      let(:params) { [[1, 2], 3, [4, 5, 6]] }
      let(:sql) { 'SELECT ARRAY[$1, $2], $3, ARRAY[$4, $5, $6]' }

      it_behaves_like 'builds proper sql & binds'
    end

    context 'when target list is insufficient' do
      let(:query) { 'select $1, $2, $3' }
      let(:params) { [[1, 2]] }
      let(:fail_msg) do
        <<~MSG.strip
          No parameter for $2
          select $1, $2, $3
                     ^-^
        MSG
      end

      it 'raises error' do
        expect do
          subject.sql
        end.to raise_error(PgExecArrayParams::Error, fail_msg)
      end
    end

    context 'when ref params' do
      let(:query) { 'select * from t1 where a1 = $1 and a2 = $2 and a3 = $3 and a4 = $4' }
      let(:sql) { 'SELECT * FROM "t1" WHERE "a1" = $1 AND "a2" IN ($2, $3) AND "a3" = $4 AND "a4" IN ($5, $6)' }

      it_behaves_like 'builds proper sql & binds'
    end

    context 'when ref params are insufficient' do
      let(:query) { 'select * from t1 where a1 = $1 and a2 = $2 and a3 = $3 and a4 = $4 and a5 = $5' }
      let(:fail_msg) do
        <<~MSG.strip
          No parameter for $5
          select * from t1 where a1 = $1 and a2 = $2 and a3 = $3 and a4 = $4 and a5 = $5
                                                                                      ^-^
        MSG
      end

      it 'raises error' do
        expect do
          subject.sql
        end.to raise_error(PgExecArrayParams::Error, fail_msg)
      end
    end

    context 'when ref params reversed' do
      let(:query) { 'select * from t1 where a3 = $3 and a1 = $1 and a4 = $4 and a2 = $2' }
      let(:sql) { 'SELECT * FROM "t1" WHERE "a3" = $4 AND "a1" = $1 AND "a4" IN ($5, $6) AND "a2" IN ($2, $3)' }

      it_behaves_like 'builds proper sql & binds'
    end

    context 'when target list and ref params reversed' do
      let(:query) { 'select $2 from t1 where a3 = $3 and a1 = $1 and a4 = $4' }
      let(:sql) { 'SELECT ARRAY[$2, $3] FROM "t1" WHERE "a3" = $4 AND "a1" = $1 AND "a4" IN ($5, $6)' }

      it_behaves_like 'builds proper sql & binds'
    end
  end
end
