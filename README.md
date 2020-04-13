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
	steamid = { type = 'number', max_length = 50, unique = true },
	username = { type = 'char', max_length = 100 },
	password = { type = 'char', max_length = 50 },
	age = { type = 'number', max_length = 2 },
	job = { type = 'char', max_length = 50, null = true, default = 'foo'},
	description = { type = 'text', null = true },
	registered_at = { type = 'datetime', null = true }
}, true)
```

Note, the `force_recreate` is optional and defaults to false.

## Schema Options

* type - Maps to DB datatype.  Must be one of char, text, number, or datetime.
* max_length - Maximum length allowed for the value.
* unique - Enforce uniqueness on this value.
* null - Whether or not NULL value is allowed.  Defaults to false.
* default - Default value is one isn't specified.

## Select Rows

```
DBM.SelectRows(<table_name>, <fields>, <where>)
```

TODO: Not yet implemented

## Insert Row

```
DBM.InsertRow(<table_name>, <params>)
```

Example:
```
DBM.InsertRow("users", { steamid = 9876543210, username = 'oweff', password = 'dontknow', age = 25 })

# INSERT INTO `users` (`job`, `password`, `username`, `description`, `age`, `steamid`, `registered_at`) VALUES (NULL, 'dontknow', 'oweff', NULL, 25, 1286608618, NULL)
```

## Update Rows

```
DBM.UpdateRows(<table_name>, <params>, <where>)
```

Example:
```
DBM.UpdateRows("users", { steamid = 9876543210 }, { age = 28, password = 'password1' })

# UPDATE users SET steamid = 1286608618 WHERE (password = 'password1' AND age = 28)
```

## Delete Rows

```
DBM.DeleteRows(<table_name>, <where>)
```

TODO: Not yet implemented

# TODO

* Query builder to support more operators (AND, OR, LIKE, EQ, GT, LT)