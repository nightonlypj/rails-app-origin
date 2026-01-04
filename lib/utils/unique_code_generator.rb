module Utils
  module UniqueCodeGenerator
    def self.base36_uuid
      SecureRandom.uuid.delete('-').to_i(16).to_s(36).rjust(25, '0') # 16進数32桁+ハイフン4つ -> 36進数25桁
    end
  end
end
