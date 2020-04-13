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
                column_query = column_query .. " DEFAULT(" .. QuoteValue(field.default, field.type) ..")"
            end

            if field.unique ~= nil then
                column_query = column_query .. " UNIQUE"
            end

            create_query = create_query .. column_query .. ","
        end
        create_query = create_query .. "\nPRIMARY KEY (id)\n)"

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
            value = params[column] or "NULL"

            if ValidateField(value, field) then
                value = QuoteValue(value, field.type)
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
        return mariadb_get_insert_id()
    end

    --
    -- UPDATE 
    --    
    self.update = function(params)
        print("updating row "..self.name)
        print(dump(params))
        return true
    end

    return self
end

