Table = {}

function Table.new(conn, name, fields)
    local self = {}
    self.conn = conn
    self.name = name
    self.fields = fields

    if DBM_DEBUG == true then
        print("initializing schema "..name)
        print(dump(self.fields))
    end

    self.schema_exists = function()
        local query = mariadb_prepare(self.conn, "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '?' AND table_name = '?'", DBM_DATABASE, self.name)
        mariadb_query(self.conn, query, function()
            if (mariadb_get_value_index_int(1, 1) ~= "1") then
                self.create_schema()
            end
        end)
    end

    self.drop_schema = function()
        if DBM_DEBUG == true then
            print("dropping schema "..self.name)
        end
        local query = mariadb_prepare(self.conn, "DROP TABLE ?", self.name)
        mariadb_query(self.conn, query)
    end

    self.create_schema = function(force_recreate)
        if force_recreate == true then
            self.drop_schema()
        end

        if DBM_DEBUG == true then
            print("creating table "..self.name)
        end

        local create_query = "CREATE TABLE IF NOT EXISTS `" .. self.name .. "` \n("
        local counter = 0
        local column_query

        for name,opts in pairs(self.fields) do
            column_query = "\n     `" .. name .. "` " .. GetNativeDataType(opts.type)

            if opts.max_length ~= nil then
                column_query = column_query .. "(" .. opts.max_length ..")"
            end

            if opts.null == nil or opts.null == false then
                column_query = column_query .. " NOT NULL"
            end

            if opts.default ~= nil then
                column_query = column_query .. " DEFAULT(" .. TypeFormatDefault(opts) ..")"
            end

            if opts.unique ~= nil then
                column_query = column_query .. " UNIQUE"
            end

            if counter ~= 0 then
                column_query = "," .. column_query
            end
            create_query = create_query .. column_query
            counter = counter + 1
        end
        create_query = create_query .. "\n)"

        if DBM_DEBUG == true then
            print(create_query)
        end

        local query = mariadb_prepare(self.conn, create_query)
        mariadb_query(self.conn, query)
        return true
    end

    self.insert = function(params)
        if DBM_DEBUG == true then
            print("inserting table "..self.name)
            print(dump(params))
        end

        local insert_query = "INSERT INTO `" .. self.name .. "` ("
        local counter = 0
        local values = ""
        local colname
        local value
        for column,field in pairs(self.fields) do
            colname = column
            value = params[column] or "NULL"

            if ValidateField(value, field) then
                value = self.parsed_escape_value(value, field)
            else
                print("Wrong type for table "..self.name.." in column "..colname)
                return false
            end

            colname = "`" .. colname .. "`"
            if counter ~= 0 then
                colname = ", " .. colname
                value = ", " .. value
            end

            values = values .. value
            insert_query = insert_query .. colname

            counter = counter + 1
        end

        insert_query = insert_query .. ") VALUES (" .. values .. ")"

        if DBM_DEBUG == true then
            print(insert_query)
        end

        local query = mariadb_prepare(self.conn, insert_query)
        local result = mariadb_query(self.conn, query)
        return true
    end

    self.update = function(params)
        if DBM_DEBUG == true then
            print("updating table "..self.name)
            print(dump(params))
        end
        return true
    end

    -- Escapes value for safe SQL insertion
    self.parsed_escape_value = function(value, field)
        if field.type then
            if field.type == "text" or field.type == "char" then
                value = "'" .. mariadb_escape_string(self.conn, value) .. "'"
            end
        end
        return value
    end

    return self
end

function GetNativeDataType(type)
    if type == "number" then
        return "int"
    elseif type == "char" then
        return "varchar"
    else
        return type
    end
end

function TypeFormatDefault(opts)
    if opts.type == "char" or opts.type == "text" then
        return "'" .. opts.default .. "'"
    else
        return opts.default
    end
end

-- TODO
function ValidateField(value, field)
    return true
end
