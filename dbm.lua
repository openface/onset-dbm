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

function InsertRow(name, params)
    return Tables[name].insert(params)
end
AddFunctionExport("InsertRow", InsertRow)

function UpdateRows(name, params, where)
    return Tables[name].update(params, where)
end
AddFunctionExport("UpdateRows", UpdateRows)

function SelectRows(name, fields, where, callback)
    print "YO"
    print(callback)

    return Tables[name].select(fields, where, callback)
end
AddFunctionExport("SelectRows", SelectRows)


--

function FormatDateTime(time)
    return os.date("%Y-%m-%d %H:%M:%S", time)
end
AddFunctionExport("FormatDateTime", FormatDateTime)

function FormatDataType(type)
    if type == "number" then
        return "INT"
    elseif type == "char" then
        return "VARCHAR"
    elseif type == "text" then
        return "TEXT"
    elseif type == "datetime" then
        return "DATETIME"
    else
        print("Unreconized data type: "..type)
        return type
    end
end

-- Handles NULL strings and quotes for SQL statements
function FormatValue(value, field)
    if field.type == "char" or field.type == "text" or field.type == "datetime" then
        if value == nil and field.null ~= false then
            return "NULL"
        else
            return "'" .. tostring(value) .. "'"
        end
    else
        -- integers
        if value == nil then
            return "NULL"
        else 
            return value
        end
    end
end

-- TODO
function ValidateField(value, field)
    return true
end

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