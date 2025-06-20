require 'rails_helper'

RSpec.describe Product, type: :model do
  it { should belong_to(:category) }
  it { should belong_to(:user) }

  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:price) }
  it { should validate_numericality_of(:price).is_greater_than(0) }
  it { should validate_presence_of(:stock) }
  it { should validate_numericality_of(:stock).is_greater_than_or_equal_to(0) }
end
