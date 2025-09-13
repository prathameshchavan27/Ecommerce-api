class Product::Searching
    def initialize(params = {})
        @query = params[:search].to_s.strip
        @page = (params[:page] || 1).to_i
        @per_page = (params[:per_page] || 10).to_i
    end

    def call
        products = Product.left_joins(:category)
        if @query.present?
            products = products.where("products.title ILIKE :q OR products.description ILIKE :q OR categories.name ILIKE :q", q: "%#{@query}%")
        end
        products.page(@page).per(@per_page)
    end
end
