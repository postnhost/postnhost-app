require "rails_helper"

RSpec.describe Postnhost::Language do
  describe "database seeds" do
    it "creates only required language records and remains idempotent" do
      allow(Postnhost::SampleData).to receive(:seed!)

      expect do
        2.times { load Rails.root.join("db/seeds.rb").to_s }
      end.to output(/Required seed data created successfully!/).to_stdout

      expect(described_class.count).to eq(9)
      expect(Postnhost::User.exists?).to be(false)
      expect(Postnhost::Category.exists?).to be(false)
      expect(Postnhost::Article.exists?).to be(false)
      expect(Postnhost::SampleData).not_to have_received(:seed!)
    end
  end
end
