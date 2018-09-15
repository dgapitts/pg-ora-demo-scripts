CREATE DATABASE bench1;
\c bench1
create user bench1 with password :newpassword;
GRANT ALL PRIVILEGES ON DATABASE bench1 to bench1;
