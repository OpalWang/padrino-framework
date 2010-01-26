module Padrino
  module Generators
    module Components
      module Orms

        module ActiverecordGen

          AR = (<<-AR).gsub(/^ {10}/, '')
          ##
          # You can use other adapters like:
          # 
          #   ActiveRecord::Base.configurations[:development] = {
          #     :adapter  => "mysql",
          #     :host     => "localhost",
          #     :username => "myuser",
          #     :password => "mypass",
          #     :database => "somedatabase"
          #   )
          #
          ActiveRecord::Base.configurations[:development] = {
            :adapter => 'sqlite3',
            :database => Padrino.root('db', "development.db")
          }

          ActiveRecord::Base.configurations[:production] = {
            :adapter => 'sqlite3',
            :database => Padrino.root('db', "production.db")
          }

          ActiveRecord::Base.configurations[:test] = {
            :adapter => 'sqlite3',
            :database => Padrino.root('db', "test.db")
          }

          # Setup our logger
          ActiveRecord::Base.logger = logger

          # Include Active Record class name as root for JSON serialized output.
          ActiveRecord::Base.include_root_in_json = true

          # Store the full class name (including module namespace) in STI type column.
          ActiveRecord::Base.store_full_sti_class = true

          # Use ISO 8601 format for JSON serialized times and dates.
          ActiveSupport.use_standard_json_time_format = true

          # Don't escape HTML entities in JSON, leave that for the #json_escape helper.
          # if you're including raw json in an HTML page.
          ActiveSupport.escape_html_entities_in_json = false

          # Now we can estabilish connection with our db
          ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[Padrino.env])
          AR

          RAKE = (<<-RAKE).gsub(/^ {10}/, '')
          require 'sinatra/base'
          require 'active_record'

          namespace :db do
            desc "Migrate the database"
            task(:migrate) do
              load File.dirname(__FILE__) + '/config/boot.rb'
              APP_CLASS.new
              ActiveRecord::Base.logger = Logger.new(STDOUT)
              ActiveRecord::Migration.verbose = true
              ActiveRecord::Migrator.migrate( File.dirname(__FILE__) + "/db/migrate")
            end
          end
          RAKE


          def setup_orm
            require_dependencies 'active_record'
            create_file("config/database.rb", AR)
            create_file("Rakefile", RAKE.gsub(/APP_CLASS/, @class_name))
            empty_directory('app/models')
          end

          AR_MODEL = (<<-MODEL).gsub(/^ {10}/, '')
          class !NAME! < ActiveRecord::Base

          end
          MODEL

          def create_model_file(name, fields)
            model_path = destination_root('app/models/', "#{name.to_s.underscore}.rb")
            model_contents = AR_MODEL.gsub(/!NAME!/, name.to_s.downcase.camelize)
            create_file(model_path, model_contents,:skip => true)
          end

          AR_MIGRATION = (<<-MIGRATION).gsub(/^ {10}/, '')
          class !FILECLASS! < ActiveRecord::Migration
            def self.up
              !UP!
            end

            def self.down
              !DOWN!
            end
          end
          MIGRATION

          AR_MODEL_UP_MG = (<<-MIGRATION).gsub(/^ {6}/, '')
          create_table :!TABLE! do |t|
            # t.column <name>, <type>
            # t.column :age, :integer
            !FIELDS!
          end
          MIGRATION

          AR_MODEL_DOWN_MG = (<<-MIGRATION).gsub(/^ {10}/, '')
          drop_table :!TABLE!
          MIGRATION

          def create_model_migration(migration_name, name, columns)
            output_model_migration(migration_name, name, columns,
                 :base => AR_MIGRATION,
                 :column_format => lambda { |field, kind| "t.#{kind.underscore.gsub(/_/, '')} :#{field}" },
                 :up => AR_MODEL_UP_MG, :down => AR_MODEL_DOWN_MG)
          end

          AR_CHANGE_MG = (<<-MIGRATION).gsub(/^ {6}/, '')
          change_table :!TABLE! do |t|
            !COLUMNS!
          end
          MIGRATION

          def create_migration_file(migration_name, name, columns)
            output_migration_file(migration_name, name, columns,
                :base => AR_MIGRATION, :change_format => AR_CHANGE_MG,
                :add => lambda { |field, kind| "t.#{kind.underscore.gsub(/_/, '')} :#{field}" },
                :remove => lambda { |field, kind| "t.remove :#{field}" })
          end

        end
      end
    end
  end
end
