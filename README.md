= DBM: Database Manager for Onset

A simple lightweight library for handling CRUD operations to your database.

== Import DBM Package

```
DBM = ImportPackage("dbm")
```

== Configure Database

Copy the `config.lua.example` file and name it `config.lua`.  Edit it to provide
your database credentials.   The database MUST already exist.  DBM can create the
table schemas for you, but not the database.

== Initialize/Create Table

```
DBM.InitTable(<table_name>, <fields>, [<force_recreate>])
```

Example:
```
DBM.InitTable("users", {
	username = {type = 'char', max_length = 100, unique = true},
	password = {type = 'char', max_length = 50, unique = true},
	age = {type = 'number', max_length = 2 },
	job = {type = 'char', max_length = 50, null = true, default = 'foo'},
	description = {type = 'text', null = true },
	time_create = {type = 'datetime', null = true}
})
```

Note, `force_recreate` defaults to false if omitted.

TODO: document data types

== Insert Row

== Update Row

== Delete Row

== Fetch Rows

== Fetch Single Row

= TODO

* Auto-generate primary key (id)
* Auto-generate timestamps (created_at, updated_at)