# DBM: Database Manager for Onset

A simple lightweight library for handling CRUD operations in your database.

## Configure Database Settings

Copy the `config.lua.example` file and name it `config.lua`.  Edit it to provide
your database credentials.   The database MUST already exist.  DBM can create the
table schemas for you, but not the database.

## Import DBM Package

```
DBM = ImportPackage("dbm")
```

## Initialize/Create Table

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

Note, the `force_recreate` is optional and defaults to false.

## Schema Options

* type - Maps to DB datatype.  Must be one of char, text, number, or datetime.
* max_length - Maximum length allowed for the value.
* unique - Enforce uniqueness on this value.
* null - Whether or not NULL value is allowed.  Defaults to false.
* default - Default value is one isn't specified.


## Insert Row

```
#
DBM.InsertRow("users", { username = 'nick', password = 'bill', age = 25 })
```

## Update Rows

```
DBM.UpdateRows(<table_name>, <params>, <where>)
```

Example:
```
# UPDATE users SET age = 25, steamid = 1234567890 WHERE (password = 'password1' AND age = 28)

DBM.UpdateRow("users", { steamid = 1234567890, age = 25 }, { age = 28, password = 'password1' })

```

## Delete Row

## Fetch Rows

```
#
DBM.Select()
```

## Fetch Single Row

# TODO

* Auto-generate primary key (id)
* Auto-generate timestamps (created_at, updated_at)