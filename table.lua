Table = {}

function Table.new(conn, name, fields)
    local self = {}
    self.conn = conn
    self.name = name
    self.fields = fields

    self.schema_exists = function()
        local query = mariadb_prepare(self.conn, "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '?' AND table_name = '?'", DBM_DATABASE, self.name)
        mariadb_query(self.conn, query, function()
            if (mariadb_get_value_index_int(1, 1) ~= "1") then
                self.create_schema()
            end
        end)
    end

    --
    -- DROP 
    --
    self.drop_schema = function()
        print("dropping schema "..self.name)
        local query = mariadb_prepare(self.conn, "DROP TABLE ?", self.name)
        mariadb_query(self.conn, query)
    end

    --
    -- CREATE 
    --    
    self.create_schema = function(force_recreate)
        if force_recreate == true then
            self.drop_schema()
        end

        print("creating table "..self.name)

        local create_query = "CREATE TABLE IF NOT EXISTS `" .. self.name .. "` \n("
        create_query = create_query .. "\n`id` int NOT NULL AUTO_INCREMENT,"
        local column_query

        for name,field in pairs(self.fields) do
            column_query = "\n`" .. name .. "` " .. FormatDataType(field.type)

            if field.max_length ~= nil then
                column_query = column_query .. "(" .. field.max_length ..")"
            elseif field.type == "char" then
                -- set length if not given for char type
                column_query = column_query .. "(255)"
            end

            if field.null == nil or field.null == false then
                column_query = column_query .. " NOT NULL"
            end

            if field.default ~= nil then
                column_query = column_query .. " DEFAULT(" .. FormatValue(field.default, field) ..")"
            end

            if field.unique ~= nil then
                column_query = column_query .. " UNIQUE"
            end

            create_query = create_query .. column_query .. ","
        end

        -- automatic timestamps on create/update (Requires MySQL 5.6)
        create_query = create_query .. "\n`created_at` TIMESTAMP NOT NULL DEFAULT NOW(),"
        create_query = create_query .. "\n`updated_at` TIMESTAMP NOT NULL DEFAULT NOW() ON UPDATE NOW(),"
        create_query = create_query .. "\nPRIMARY KEY (`id`)\n)"

        local query = mariadb_prepare(self.conn, create_query)
        mariadb_query(self.conn, query)
        return true
    end

    --
    -- INSERT 
    --
    self.insert = function(params)
        print("inserting row "..self.name)
        print(dump(params))

        local insert_query = "INSERT INTO `" .. self.name .. "` ("

        local counter = 0
        local values = ""
        local colname
        local value
        for column,field in pairs(self.fields) do
            colname = column
            value = params[column]

            if ValidateField(value, field) then
                value = FormatValue(value, field)
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

        local query = mariadb_prepare(self.conn, insert_query)
        local result = mariadb_query(self.conn, query)
        return true
    end

    --
    -- UPDATE 
    --    
    self.update = function(params, where)
        print("updating row "..self.name)
        print(dump(where))
        print(dump(params))

        local update_query = "UPDATE "..self.name.." SET "
        local counter = 0

        for column,value in pairs(params) do
            if counter ~= 0 then
                update_query = update_query .. ", "
            end

            if type(value) ~= "number" then
                value = "'"..value.."'"
            end

            update_query = update_query .. column ..' = '..value
            counter = counter + 1
        end

        -- append where clause
        update_query = update_query .. " " .. self._where(where)

        local query = mariadb_prepare(self.conn, update_query)
        local result = mariadb_query(self.conn, query)
        return true
    end

    -- @param fields    "id,name,dob"
    -- @param where     { age = 25 }
    -- @param callback  function
    self.select = function(fields, where, callback)
        local select_query = "SELECT "..fields.." FROM "..self.name

        -- append where clause
        select_query = select_query .. " " .. self._where(where)

        local query = mariadb_prepare(self.conn, select_query)
        local result = mariadb_query(self.conn, query, callback)
        return true
    end

    -- builds a where clause
    -- TODO: support more operators
    self._where = function(where)
        print "WHERE"
        print(dump(where))
        local where_clause = "WHERE ("
        local counter = 0
        local condition = ""
        local equation

        for column,value in pairs(where) do

            if type(value) ~= "number" then
                value = "'"..value.."'"
            end

            equation = column .. ' = ' .. value

            if counter ~= 0 then
                equation = " AND "..equation
            end

            condition = condition .. equation
            counter = counter + 1
        end
        where_clause = where_clause .. condition .. ")"
        return where_clause
    end

    return self
end
