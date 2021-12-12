# リリースノート

## 1.4.0 (Sprint 9)

- Deviseのview specを作成したい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/440/
- お知らせの未読数・ラベル・大切なお知らせを表示したい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/436/
- アカウントロック直後とその後でメッセージを分けたい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/435/
- パスワード再設定APIで成功しロック中の場合はロックを解除したい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/429/
- アカウント削除APIで送信されるメールの取り消しURLにフロントURLを入れたい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/432/
- メールアドレス確認APIで確認済みの場合はaccount_confirmation_success=trueを返して欲しい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/428/
- seedで特定の状態のテストユーザーを作成したい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/419/
- ユーザーの登録情報詳細を取得できるAPIが欲しい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/414/
- Devise Token Authのuidをメールアドレスからidに変更したい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/413/
- ログイン状態でもAPIログインできるようにしたい（フロントとの不整合に対応）
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/411/
- 異なるドメインからAPIにアクセスできるようにしたい（CROS設定）
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/410/

### Bug

- ブラウザで.jsonのURLにアクセスできないようにしたい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/439/
- ログインAPIでアカウントロック時に送信されるメールの解除URLにリダイレクトURLが入らない
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/423/
- ログインAPIで「注意：もう一回間違えるとアカウントがロックされます。」が表示されない
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/422/
- 登録情報変更APIでメールアドレス変更時に送信されるメールの確認URLにリダイレクトURLが入らない
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/425/
- メールアドレス確認APIで送信されるメールの確認URLにリダイレクトURLが入らない
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/426/
- acceptヘッダにjsonと*が含まれるとtemplateエラーになる
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/412/

## 1.3.0 (Sprint 8)

- 認証と登録をAPIでもできるようにしたい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/388/
- SimpleCov導入：カバレッジを見れるようにしたい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/395/
- SchemaSpy導入：DB設計・ER図を自動生成したい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/394/
- Docker導入：環境構築を簡単にしたい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/393/
- Bullet導入：N+1に気付けるようにしたい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/392/

## 1.2.0 (Sprint 7)

- モデルベースのER図を自動生成したい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/377/

## 1.1.0 (Sprint 4-6)

- deviseのページ：POST後のURLをGETした時にRouting Errorや違うページに行かないようにしたい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/345/
- jQueryを導入したい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/341/
- 最低限のドキュメントを作成するようにしたい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/152/
- フロントにマテリアルデザインを導入したい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/124/
- 環境構築手順とリリースノートを作りたい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/304/
- Ruby3.0に対応したい（Gemのバージョンアップも）
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/321/
- robots.txtでの許可/拒否を環境毎に変えたい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/323/
- サーバーはUnicornで動かした
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/307/
- MySQLに対応したい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/305/
- ユーザーにお知らせ通知したい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/289/
- ユーザーコードを追加したい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/286/
- ユーザー名と画像を設定できるようにしたい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/252/
- RSpecのshared_contextを共通化したい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/262/
- トークンの期限が切れたらメールアドレス確認待ちを非表示にしたい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/186/
- アカウント削除後、一定期間はログインおよび取り消しができるようにしたい
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/178/

### Bug

- チェックボックスが左にズレる
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/342/
- radioボタンのバリデーションエラーでデザインが崩れる
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/298/
- ログアウト -> No route matches [GET] "/users/sign_out"
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/330/
- ActionView::Template::Error(FATAL ERROR: wasm code commit Allocation failed - process out of memory)
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/328/
- RSpecでユーザー名が重複して失敗する事がある
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/285/
- ActionMailer Previewでユーザーが作成される
  - https://dev.azure.com/nightonly/rails-app-origin/_workitems/edit/193/

## 1.0.0

- 初期バージョン
