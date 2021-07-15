create table classes(
	id int primary key identity(1,1),
	class_name nvarchar(50) not null,
	create_time datetime default(getdate()) not null
)
go

create table students(
	id int primary key identity(1,1),
	class_id int foreign key references classes(id) not null,
	stu_name nvarchar(50) not null,
	create_time datetime default(getdate()) not null
)
go

create table courses(
	id int primary key identity(1,1),
	course_name nvarchar(50) not null,
	create_time datetime default(getdate()) not null
)
go

create table scores(
	stu_id int foreign key references students(id) not null,
	course_id int foreign key references courses(id) not null,
	score float not null,
	create_time datetime default(getdate()) not null
)
go

create index idx_scores_sid on scores(stu_id)
go

create index idx_scores_cid on scores(course_id)
go