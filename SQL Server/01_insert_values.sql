insert into classes(class_name) values 
(N'一年级一班'),
(N'一年级二班'),
(N'一年级三班'),
(N'二年级一班'),
(N'二年级二班'),
(N'二年级三班')
go

insert into students(class_id, stu_name) values
(1, N'王蕾'),
(1, N'章子怡'),
(2, N'李叔同'),
(2, N'王晓'),
(3, N'张小龙'),
(3, N'吴彤'),
(4, N'范跑跑'),
(4, N'李思琪'),
(5, N'郭嘉'),
(5, N'王婉'),
(6, N'柳如梦'),
(6, N'王慧娟')
go

insert into courses(course_name) values
(N'语文'),(N'数学'),(N'英语')
go