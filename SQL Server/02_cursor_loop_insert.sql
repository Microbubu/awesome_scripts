-- Cursor loop
begin tran t2
	declare @sid int
	declare sid_cursor cursor for
		select id from students
	open sid_cursor
	fetch next from sid_cursor into @sid

	while @@FETCH_STATUS = 0
	begin
		declare @cid int
		declare cid_cursor cursor for
			select id from courses
		open cid_cursor
		fetch next from cid_cursor into @cid

		while @@FETCH_STATUS = 0
		begin
			insert into scores(stu_id, course_id, score) values(@sid, @cid, rand()*100)
			print 'inserted:' + cast(@sid as varchar) + ',' + cast(@cid as varchar)
			fetch next from cid_cursor into @cid
		end

		close cid_cursor
		deallocate cid_cursor
	fetch next from sid_cursor into @sid
	end

	close sid_cursor
	deallocate sid_cursor
commit tran t2
go