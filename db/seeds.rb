# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
puts "🌱 Seeding data..."

# Clear old data
User.destroy_all
Category.destroy_all
Product.destroy_all

# Users
admin = User.create!(
  email: 'admin@example.com',
  password: 'password',
  role: 'admin'
)

seller = User.create!(
  email: 'seller@example.com',
  password: 'password',
  role: 'seller'
)

customer = User.create!(
  email: 'customer@example.com',
  password: 'password',
  role: 'customer'
)

puts "👤 Created users: admin, seller, customer"

# Categories
electronics = Category.create!(name: 'Electronics')
books = Category.create!(name: 'Books')
clothing = Category.create!(name: 'Clothing')

puts "📁 Created categories: Electronics, Books, Clothing"

# Products (owned by seller)
Product.create!([
  {
    title: 'Smartphone',
    description: 'Latest model with AMOLED display',
    price: 499.99,
    stock: 50,
    category: electronics,
    user: seller
  },
  {
    title: 'Laptop',
    description: '16GB RAM, 512GB SSD',
    price: 899.99,
    stock: 30,
    category: electronics,
    user: seller
  },
  {
    title: 'Programming Ruby',
    description: 'Ruby book for advanced programmers',
    price: 39.99,
    stock: 100,
    category: books,
    user: seller
  },
  {
    title: 'Rails Recipes',
    description: 'Tips and techniques for Rails devs',
    price: 29.99,
    stock: 80,
    category: books,
    user: seller
  },
  {
    title: 'T-Shirt',
    description: '100% cotton unisex tee',
    price: 19.99,
    stock: 200,
    category: clothing,
    user: seller
  },
  {
    title: 'Jeans',
    description: 'Slim fit denim',
    price: 49.99,
    stock: 150,
    category: clothing,
    user: seller
  }
])

puts "🛍️ Created 6 sample products"

puts "✅ Done seeding!"
