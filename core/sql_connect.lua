-- in case of sqlite connection add directory = "dbfiledirectory" to info table.

local info = {
	host = 'localhost',
	user = 'username',
	password = 'password',
	dbname = 'mta'
}

connection = Sql.createConnection(info)
