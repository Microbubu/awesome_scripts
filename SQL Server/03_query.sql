-- 普通的连接查询
select s.stu_name, c.class_name, cr.course_name, sc.score
from students s
left join classes c on s.class_id = c.id
left join scores sc on s.id = sc.stu_id
left join courses cr on sc.course_id = cr.id;

-- 使用over开窗将每个班级每门科目成绩最大值放到每条成绩记录中
select s.stu_name, c.class_name, cr.course_name, sc.score,
	max(sc.score) over(partition by c.id, cr.id) max_score 
from students s
left join classes c on s.class_id = c.id
left join scores sc on s.id = sc.stu_id
left join courses cr on sc.course_id = cr.id;


-- 查询每个班级每门科目成绩第一的学生及分数
select * from
(
	select s.stu_name, c.class_name, cr.course_name, sc.score,
		rank() over(partition by c.id, cr.id order by sc.score desc) rk
	from students s
	left join classes c on s.class_id = c.id
	left join scores sc on s.id = sc.stu_id
	left join courses cr on sc.course_id = cr.id
) tempTable where rk = 1;

-- 使用pivot行转列
select stu_name, class_name, [语文], [数学], [英语] from 
(
	select s.stu_name, c.class_name, cr.course_name, sc.score
	from students s
	left join classes c on s.class_id = c.id
	left join scores sc on s.id = sc.stu_id
	left join courses cr on sc.course_id = cr.id
) as sourceTable
pivot
(
	max(score) for course_name in ([语文],[数学],[英语])
) as pivotTable;
