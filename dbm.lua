require("packages/" .. GetPackageName() .. "/config")

local conn -- database connection

local function OnPackageStart()
	mariadb_log(DBM_LOGLEVEL)

	conn = mariadb_connect(DBM_HOST, DBM_USERNAME, DBM_PASSWORD, DBM_DATABASE)

	if (conn ~= false) then
		print("DBM: Connected to " .. DBM_HOST .. " port ".. DBM_PORT)
		mariadb_set_charset(conn, DBM_CHARSET)
	else
		print("DBM: Connection failed to " .. DBM_HOST .. ", see mariadb_log file")

		-- Immediately stop the server if we cannot connect
		ServerExit()
	end
end
AddEvent("OnPackageStart", OnPackageStart)

local function OnPackageStop()
	mariadb_close(conn)
end
AddEvent("OnPackageStop", OnPackageStop)

local function OnQueryError(errorid, error_str, query_str, handle_id)
    print "Database Query Error!"
    print("Error ID: "..errorid)
    print("Error: "..error_str)
    print("Query: "..query_str)
    print("HandleID: "..handle_id)
end
AddEvent("OnQueryError", OnQueryError)

--
-- Tables
--
local Tables = {}

function InitTable(name, fields, force_recreate)
    Tables[name] = Table.new(conn, name, fields)

    -- create schema, force recreate is specified
    local force_recreate = force_recreate or false
    Tables[name].create_schema(force_recreate)
end
AddFunctionExport("InitTable", InitTable)

function InsertTable(name, params)
    return Tables[name].insert(params)
end
AddFunctionExport("InsertTable", InsertTable)

function UpdateTable(name, params)
    return Tables[name].update(params)
end
AddFunctionExport("UpdateTable", UpdateTable)


--

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end