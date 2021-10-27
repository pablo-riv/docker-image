require 'rails_helper'

RSpec.describe DropOut, type: :model do
  it "Should create DropOut" do
    account = FactoryBot.create(:account)
    drop_out = account.drop_outs.create(FactoryBot.build(:drop_out).attributes)
    expect(drop_out).to be_an_instance_of(DropOut)
    expect(drop_out.deactivated).to be(true)
  end

  it "Should not create DropOut witout companies" do
    drop_out = DropOut.new
    expect(drop_out.save).to be false
  end
end
