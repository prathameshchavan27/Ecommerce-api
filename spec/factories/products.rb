FactoryBot.define do
  factory :product do
    title { "Smartphone" }
    description { "Latest model with advanced features" }
    price { 499.99 }
    stock { 10 }
    association :category
    association :user, factory: :seller
  end
end
