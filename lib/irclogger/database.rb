require 'sequel'

db_encoding = Config['database'].start_with?('mysql') ? 'utf8mb4' : 'utf8'
DB = Sequel.connect(Config['database'], :encoding => db_encoding).extension(:auto_literal_strings)
