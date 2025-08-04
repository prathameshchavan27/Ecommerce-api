FactoryBot.define do
  factory :payment do
    order { nil }
    status { "MyString" }
    stripe_payment_intent_id { "MyString" }
    amount { 1 }
    currency { "MyString" }
  end
end
