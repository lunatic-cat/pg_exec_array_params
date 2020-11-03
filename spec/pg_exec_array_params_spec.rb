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
          exec_array_params(conn, sql, [[min_age, max_age]])
        end.to raise_error(PgExecArrayParams::Error)
      end
    end

    RSpec.shared_examples 'with primitive and array' do |pattern|
      where_sql = "age #{format pattern, '$1'} OR age #{format pattern, '$2'}"

      describe "with pattern #{where_sql}" do
        let(:sql) { "select * from users where #{where_sql} order by age" }

        it 'works array last' do
          expect(exec_array_params(conn, sql, [min_age, [min_age, max_age]])).to fetch_rows [min_row, max_row]
        end

        it 'works array first' do
          expect(exec_array_params(conn, sql, [[min_age, max_age], min_age])).to fetch_rows [min_row, max_row]
        end
      end
    end

    it_behaves_like 'with primitive and array', '= %s'
    it_behaves_like 'with primitive and array', 'IN (%s)'

    describe 'random arrays of random size' do
      let(:refs_amount) { 10 }
      let(:sql_parts) { refs_amount.times.map { |x| format ['age = %s', 'age IN (%s)'].sample, "$#{x + 1}" }.shuffle }
      let(:array_params) { rand(1..4).times.map { [min_age, max_age].sample } }

      let(:sql) { "select * from users where #{sql_parts.join(' OR ')} order by age" }
      let(:params) { refs_amount.times.map { [min_age, max_age, array_params, array_params].sample } }

      it 'works' do
        expect(exec_array_params(conn, sql, params)).to fetch_rows [min_row, max_row]
      end
    end

    describe 'non-primitives inside arrays' do
      it 'raises error' do
        expect do
          exec_array_params(conn, sql, [[min_age, max_age, {}]])
        end.to raise_error(PgExecArrayParams::Error)
      end
    end
  end

  describe '#included' do
    it 'works like #exec_array_params' do
      expect(conn.exec_array_params(sql, [min_age])).to fetch_rows [min_row]
    end
  end
end
