

create database todos_db;
use todos_db;

create table todos (
    id int auto_increment primary key,
    title varchar(255) not null,
    description text,
    todo_type varchar(50) not null default 'other',
    is_completed boolean default false,
    created_at timestamp default current_timestamp,
    updated_at timestamp default current_timestamp on update current_timestamp,
    user_id int not null,
    foreign key (user_id) references users(id)
);


create table users (
    id int auto_increment primary key,
    username varchar(100) not null unique,
    email varchar(255) not null unique,
    password_hash varchar(255) not null,
    created_at timestamp default current_timestamp,
    todos_count int default 0
);

-- drop password column from users;
alter table users drop column password;