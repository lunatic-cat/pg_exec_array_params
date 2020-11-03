# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PgExecArrayParams::SqlRefIndex do
  let(:array) { [1, [2, 3], 4, [5, 6, 7], [8]] }
  subject { described_class.new(array) }

  describe '#[]' do
    it 'forwards to sql_ref_index' do
      expect(subject[3]).to eq [5, 7]
    end
  end

  describe '#sql_ref_index' do
    it 'gets inclusive flattened bounds' do
      expect(subject.sql_ref_index).to eq [1, [2, 3], 4, [5, 7], [8, 8]]
    end

    context 'when hash empty arrays' do
      let(:array) { [1, [], 3, [4]] }

      it 'counts empty array as 1 item' do
        expect(subject.sql_ref_index).to eq [1, [2, 2], 3, [4, 4]]
      end
    end
  end
end
