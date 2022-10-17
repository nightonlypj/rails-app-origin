class Download < ApplicationRecord
  belongs_to :user
  belongs_to :space, optional: true
  has_many :download_files, dependent: :destroy

  validates :target, presence: true
  validates :format, presence: true
  validates :char, presence: true
  validates :newline, presence: true

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
  enum char: {
    sjis: 1, # ShiftJIS
    utf8: 2 # UTF-8
  }, _prefix: true

  # 改行コード
  enum newline: {
    crlf: 1, # CR+LF
    lf: 2, # LF
    cr: 3 # CR
  }, _prefix: true
end
