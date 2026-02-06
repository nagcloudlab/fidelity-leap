

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
create table roles(
    id int auto_increment primary key,
    name varchar(50) not null
);

insert into roles (name) values ('ADMIN'), ('MANAGER'), ('USER');

create table user_roles(
    user_id int not null,
    role_id int not null,
    primary key (user_id, role_id),
    foreign key (user_id) references users(id),
    foreign key (role_id) references roles(id)
)

-- drop password column from users;
alter table users drop column password;