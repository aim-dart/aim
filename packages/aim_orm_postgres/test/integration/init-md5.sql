-- MD5認証用の初期化スクリプト
-- パスワード暗号化方式をMD5に設定
SET password_encryption = 'md5';

-- testユーザーのパスワードをMD5形式で再設定
ALTER USER test WITH PASSWORD 'test';
