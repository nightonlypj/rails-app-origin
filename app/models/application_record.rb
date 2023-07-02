class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  has_paper_trail

  def self.search_like
    # :nocov:
    case connection_db_config.configuration_hash[:adapter]
    when 'mysql2'
      "COLLATE #{connection_db_config.configuration_hash[:encoding]}_unicode_ci LIKE" # NOTE: 大文字・小文字を区別しない（全角・半角も）
    when 'postgresql'
      'ILIKE' # NOTE: 大文字・小文字を区別しない（全角・半角は区別される）
    else
      'LIKE'
    end
    # :nocov:
  end
end
