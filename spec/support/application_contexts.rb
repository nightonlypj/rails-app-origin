shared_context '共通ヘッダー' do
  let!(:base_headers) { { 'Host' => Settings['base_domain'] } }
  let!(:not_space_headers) { { 'Host' => "not.#{Settings['base_domain']}" } }
  let!(:json_headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }
end
