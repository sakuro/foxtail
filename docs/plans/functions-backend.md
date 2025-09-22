そもそもfoxtail-intl以下に制作しているフォーマッターはFTLのNUMBERおよびDATETIME関数に対応するために作っているものである。
Foxtailとしてそこまで重視して作成するのは本末転倒になるので、以下のように再設計する。

1. NUMBERおよびDATETIMEに対するバックエンドというインターフェイスを設ける。(Foxtail::Function::Backend)
2. 数値整形および日時整形のバックエンドとして、以下の2つを提供する。
   - ExecJS gem経由でJavaScriptランタイムを呼び出し、処理を委譲するもの (デフォルト)
   - 現行のfoxtail-intlを利用するもの
3. Foxtail::Functionbaに、どのバックエンドを用いるかの設定を行えるようにする。
4. foxtail-intlおよびcldrは現仕様で凍結し、リポジトリにタグを付けておく。
5. 将来的には独立したgemとして別のバックエンドを実装する。
