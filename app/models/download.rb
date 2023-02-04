class Download < ApplicationRecord
  belongs_to :user
  belongs_to :space, optional: true
  has_many :download_files, dependent: :destroy

  validates :target, presence: true
  validates :format, presence: true
  validates :char_code, presence: true
  validates :newline_code, presence: true
  validates :output_items, presence: true
  validates :output_items, text_array: true, if: proc { |download| download.output_items.present? }
  validates :select_items, presence: true, if: proc { |download| download.target&.to_sym == :select }
  validates :select_items, text_array: true, if: proc { |download| download.select_items.present? }
  validates :search_params, presence: true, if: proc { |download| download.target&.to_sym == :search }
  validates :search_params, text_hash: true, if: proc { |download| download.search_params.present? }
  validate :validate_output_items

  scope :search, ->(id) { where(id: id) if id.present? }
  scope :destroy_target, lambda {
    schedule_date = Time.current - Settings.download_destroy_schedule_days.days
    where(completed_at: ..schedule_date)
      .or(where(completed_at: nil, requested_at: ..schedule_date))
  }

  # ステータス
  enum status: {
    waiting: 0, # 処理待ち
    processing: 1, # 処理中
    success: 7, # 成功
    failure: 9 # 失敗
  }, _prefix: true

  # モデル
  enum model: {
    member: 1 # メンバー
  }, _prefix: true

  # 対象
  enum target: {
    select: 1, # 選択項目
    search: 2, # 検索
    all: 3 # 全て
  }, _prefix: true

  # 形式
  enum format: {
    csv: 1, # CSV
    tsv: 2 # TSV
  }, _prefix: true

  # 文字コード
  enum char_code: {
    sjis: 1, # Shift_JIS
    eucjp: 2, # EUC-JP
    utf8: 3 # UTF-8
  }, _prefix: true

  # 改行コード
  enum newline_code: {
    crlf: 1, # CR+LF
    lf: 2, # LF
    cr: 3 # CR
  }, _prefix: true

  # 区切り文字
  def col_sep
    case format.to_sym
    when :csv
      ','
    when :tsv
      "\t"
    else
      raise "format not found.(#{format})"
    end
  end

  # 改行文字
  def row_sep
    case newline_code.to_sym
    when :crlf
      "\r\n"
    when :lf
      "\n"
    when :cr
      "\r"
    else
      raise "newline_code not found.(#{newline_code})"
    end
  end

  private

  def validate_output_items
    return if errors[:output_items].present?

    notfound_items = []
    items = I18n.t("items.#{model}")
    eval(output_items).each do |output_item|
      notfound_items.push(output_item) if items[output_item.to_sym].blank?
    end

    if notfound_items.present?
      errors.add(:output_items, I18n.t('activerecord.errors.models.download.attributes.output_items.not_exist', key: notfound_items.join(', ')))
    end
  end
end
