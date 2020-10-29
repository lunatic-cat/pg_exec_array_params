# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PgExecArrayParams, :pg do
  include_context 'shared users table'

  describe '#exec_array_params' do
    it 'works with pg' do
      expect(exec_array_params(
               conn, 'select * from users where age in ($1)', [min_age]
             )).to fetch_rows [{ 'age' => min_age.to_s }]
    end
  end
end
