require "csv"   # Ruby's built-in CSV module
require "creek" # The 'creek' gem for XLSX processing

class Product::BulkUpload
    def self.call(file:, current_user:)
        new(file: file, current_user: current_user).perform
    end

    def initialize(file:, current_user:)
        @file = file
        @current_user = current_user
        @success_count = 0
        @failed_count = 0
        @errors = []
    end

    def perform
        validate_file_type!
        data = parse_spreadsheet(@file)
        puts "Data #{data}"
        ActiveRecord::Base.transaction do # Ensures all updates are committed or rolled back together
          data.each_with_index do |row, index|
            # Add a check to skip header row if it wasn't already implicitly skipped by `next if i == 0` in parse_spreadsheet,
            # especially for CSVs or if the first row is truly a header in XLSX.
            # `index + 1` gives the original row number from the spreadsheet.
            puts "row - #{row}"
            next if index == 0 && (row[:product_id].to_s.downcase == "product_id" || row[:sku].to_s.downcase == "sku")

            process_row(row, index + 1) # <--- THIS IS WHERE process_row IS CALLED!
          end
        end

        # Return a summary of the operation
        {
          message: "Bulk stock upload processed.",
          summary: {
            total_rows_attempted: data.length > 0 ? (data.length - 1) : 0, # Exclude potential header row
            success_count: @success_count,
            failed_count: @failed_count,
            errors: @errors
          }
        }
    # --- END OF MISSING PART ---
    rescue RuntimeError => e # Catch custom errors like "Unsupported file type"
        raise e # Re-raise to controller
    rescue => e # Catch any other unexpected errors during the entire process
        Rails.logger.error "Bulk upload service error: #{e.message} \n#{e.backtrace.join("\n")}"
        raise "An unexpected error occurred during bulk upload: #{e.message}"
    end

    private

    def validate_file_type!
        file_extension = File.extname(@file.original_filename).downcase
        unless [ ".csv", ".xlsx" ].include?(file_extension)
            raise "Unsupported file type. Please upload a CSV or Excel (.xlsx) file."
        end
    end

    def parse_spreadsheet(file)
        case File.extname(file.original_filename).downcase
        when ".csv"
                CSV.read(file.path, headers: true, header_converters: :symbol).map(&:with_indifferent_access)
        when ".xlsx"
                excel = Creek::Book.new(file.path)
                sheet = excel.sheets[0] # Assuming the first sheet
                header_row_data = sheet.rows.first.to_a.map { |cell_array| cell_array[1] }
                headers = header_row_data.map { |h| h.to_s.downcase.strip.to_sym }

                data = []
                sheet.rows.each_with_index do |row, i|
                    next if i == 0 # Skip header row

                    row_hash = {}
                    headers.each_with_index do |header_sym, j|
                        row_hash[header_sym] = row.to_a[j][1]
                    end
                    data << row_hash.with_indifferent_access
                end
                puts data.inspect # Debugging line to see the parsed data
                data
        else
                raise "Unsupported file type: #{File.extname(file.original_filename)}"
        end
    end

    def process_row(row, row_number)
        product_identifier = row[:product_id]
        change_quantity = row[:quantity].to_i
        puts "************#{row[:quantity]} - #{change_quantity}"
        puts change_quantity.inspect # Debugging line to see the change quantity
        unless product_identifier.present? && change_quantity.present?
            raise "Missing 'product_id'/'sku' or 'change_quantity' in row data."
        end

        @product = @current_user.products.find_by(id: product_identifier) || @current_user.products.find_by(id: product_identifier)
        puts @product.title
        raise "Product with ID/SKU '#{product_identifier}' not found or not owned by seller." if @product.nil?
        if change_quantity == 0
            raise "Change quantity cannot be zero."
        elsif change_quantity > 0
            @product.increase_stock(change_quantity)
        else
            @product.decrease_stock(change_quantity.abs)
        end
        @success_count += 1
    rescue Product::InsufficientStockError => e
        add_error(row_number, row, e.message)
    rescue => e
        add_error(row_number, row, e.message)
    end

    def add_error(row_number, row_data, message)
        @failed_count += 1
        @errors << {
        row_number: row_number,
        data: row_data.slice("product_id", "sku", "change_quantity"),
        message: message
        }
    end
end
