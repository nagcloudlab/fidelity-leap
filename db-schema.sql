

create database todos_db;
use todos_db;

create table todos (
    id int auto_increment primary key,
    title varchar(255) not null,
    description text,
    is_completed boolean default false,
    created_at timestamp default current_timestamp,
    updated_at timestamp default current_timestamp on update current_timestamp,
);

alter table todos
    add todo_type varchar(50) not null default 'general';
