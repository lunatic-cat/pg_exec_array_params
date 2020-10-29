# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PgExecArrayParams, :pg do
  include_context 'shared tables'

  let(:sql) { 'select * from users where age = $1 order by age' }
  let(:min_row) { { 'age' => min_age.to_s } }
  let(:max_row) { { 'age' => max_age.to_s } }

  RSpec.shared_examples 'replacement handler' do
    it 'working like usual' do
      expect(exec_array_params(conn, sql, [min_age])).to fetch_rows [min_row]
    end

    it 'working with array' do
      expect(exec_array_params(conn, sql, [[min_age, max_age]])).to fetch_rows [min_row, max_row]
    end
  end

  describe '#exec_array_params' do
    describe 'with = $1' do
      it_behaves_like 'replacement handler'
    end

    describe 'with IN ($1)' do
      let(:sql) { 'select * from users where age in ($1) order by age' }
      it_behaves_like 'replacement handler'
    end

    describe 'with IN ($1, $2)' do
      let(:sql) { 'select * from users where age in ($1, $2) order by age' }

      it 'raises error to leave one ref' do
        expect do
          exec_array_params(conn, sql, [[min_age, max_row]])
        end.to raise_error(PgExecArrayParams::Error)
      end
    end
  end

  describe '#included' do
    it 'works like #exec_array_params' do
      expect(conn.pg_exec_array_params(sql, [min_age])).to fetch_rows [min_row]
    end
  end
end
