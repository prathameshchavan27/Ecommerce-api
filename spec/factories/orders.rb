FactoryBot.define do
  factory :order do
    user { nil }
    total_price { "9.99" }
    status { "MyString" }
  end
end
