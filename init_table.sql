CREATE TABLE notes (
  id serial PRIMARY KEY,
  title varchar(255),
  content text,
  timestamp timestamp DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO notes(title, content)
VALUES
  ('My Notes へようこそ！', '〈変更〉ボタンで中身を変えられます！');

