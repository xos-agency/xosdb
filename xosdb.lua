-- XSA DATABASE (XSADB)
-- Copyright 2015
-- XOUT SECURITY AGENCY (XSA)

function wrap(str, limit, indent, indent1) indent = indent or "" indent1 = indent1 or indent limit = limit or 72 local here = 1-#indent1 return indent1..str:gsub("(%s+)()(%S+)()", function(sp, st, word, fi) if fi-here > limit then here = st - #indent return "\n"..indent..word end end) end

local index_table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function to_binary(integer)
    local remaining = tonumber(integer)
    local bin_bits = ''

    for i = 7, 0, -1 do
        local current_power = math.pow(2, i)

        if remaining >= current_power then
            bin_bits = bin_bits .. '1'
            remaining = remaining - current_power
        else
            bin_bits = bin_bits .. '0'
        end
    end

    return bin_bits
end

function from_binary(bin_bits)
    return tonumber(bin_bits, 2)
end


function string.to_base64(to_encode)
    local bit_pattern = ''
    local encoded = ''
    local trailing = ''

    for i = 1, string.len(to_encode) do
        bit_pattern = bit_pattern .. to_binary(string.byte(string.sub(to_encode, i, i)))
    end

    -- Check the number of bytes. If it's not evenly divisible by three,
    -- zero-pad the ending & append on the correct number of ``=``s.
    if math.mod(string.len(bit_pattern), 3) == 2 then
        trailing = '=='
        bit_pattern = bit_pattern .. '0000000000000000'
    elseif math.mod(string.len(bit_pattern), 3) == 1 then
        trailing = '='
        bit_pattern = bit_pattern .. '00000000'
    end

    for i = 1, string.len(bit_pattern), 6 do
        local byte = string.sub(bit_pattern, i, i+5)
        local offset = tonumber(from_binary(byte))
        encoded = encoded .. string.sub(index_table, offset+1, offset+1)
    end

    return string.sub(encoded, 1, -1 - string.len(trailing)) .. trailing
end


function string.from_base64(to_decode)
    local padded = to_decode:gsub("%s", "")
    local unpadded = padded:gsub("=", "")
    local bit_pattern = ''
    local decoded = ''

    for i = 1, string.len(unpadded) do
        local char = string.sub(to_decode, i, i)
        local offset, _ = string.find(index_table, char)
        if offset == nil then
             error("Invalid character '" .. char .. "' found.")
        end

        bit_pattern = bit_pattern .. string.sub(to_binary(offset-1), 3)
    end

    for i = 1, string.len(bit_pattern), 8 do
        local byte = string.sub(bit_pattern, i, i+7)
        decoded = decoded .. string.char(from_binary(byte))
    end

    local padding_length = padded:len()-unpadded:len()

    if (padding_length == 1 or padding_length == 2) then
        decoded = decoded:sub(1,-2)
    end
    return decoded
end

function string.from_hex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

function string.to_hex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end

function string.to_7bit(str)
	--padding
	for i=1,#str%7 do
		str = str ..' '
	end
	local temp = ''
	for i = 1,#str do
		temp = temp ..(string.sub(to_binary(string.byte(str:sub(i,i))),2,8))
	end
	--print(temp,#temp)
	local temp2=''
	for i = 1,#temp,8 do
		temp2=temp2 .. (string.char(from_binary(string.sub(temp,i,i+7))))
	end
	--print(temp2,#temp2)
	return temp2
end

function string.from_7bit(str)
	local temp1 = ''
	for i = 1, #str do
		temp1 = temp1 .. to_binary(string.byte(string.sub(str,i,i)))
	end
	local temp2 = ''
	for i = 1, #temp1,7 do
		temp2 = temp2 .. string.char(from_binary('0'..string.sub(temp1,i,i+6)))
	end
	return (temp2)
end

--------------------------------------------

db={}
--db = {["XSA"] = string.to_7bit("XOUT SECURITY AGENCY - Official Document")}
filename = "xoutdb.db"
version = "3.0.0826"

print("\27[32mX.S.A. DataBase Client: \27[0m" .. version)
while #filename == 0 do
	io.write("\27[38;5;34mDatabase: ")
	filename=io.read()
end

xsadb = {}
xsadb.set = function(s) table.insert(db, s) end

print("\27[32mXSADB Status:\27[0m      Opening Database.")

fp, err = io.open( filename, "r" )
if fp ~= nil then
	while true do
		line = fp:read("*line*")
		if line == nil then break end
		xsadb.set(line)
	end
	fp:close()
end

xsadb.showAll = function() print("\n\27[32mKey", "Value")
	print("---     -----\27[0m")
	for k,v in pairs(db) do
		print(k,wrap(v:from_7bit(),72,'\t',''),"\n")
	end
	print("\27[32m---     -----\27[0m")
end

xsadb.search = function()
	io.write("Search: ")
	query = io.read()
	print()
	print("\27[32m-------- Search Results --------\27[0m")
	found = 0
	print("\27[1mKey", "Value")
	print("---     -----\27[0m")
	for k,v in pairs(db) do
		if string.find(string.lower(v:from_7bit()),string.lower(query)) then
			found = found + 1
			--print(k,v,"\n")
			print("\27[32m" .. k .. "\27[0m",string.gsub(wrap(v:from_7bit(),72,'\t',''),query,"\27[4m\27[1m\27[34m" .. query .. "\27[0m"),"\n")
		end
	end
	print()
	print("\27[1mQuery:        " .. query)
	print("Search Found: " .. found .. "\27[0m")
	print("\27[32m---------- End Search ----------\27[0m")
end

xsadb.delete = function()
	io.write("Key ID: ")
	local temp = io.read()
	if tonumber(temp) then
		local n = tonumber(temp)
		db[n] = nil
	else
		print("\27[31mKey ID MUST be a Number.\27[0m")
	end
end

-- MAIN PROGRAM LOOP
print("\27[32mXSADB Console:\27[0m     READY")
io.write("\n#! ")
kmnd = io.read()
while kmnd ~= "exit" do
	if kmnd == "set" then
		io.write("Value: ")
		xsadb.set(string.to_7bit(io.read()))
	elseif kmnd == "search" then
		xsadb.search()
	elseif kmnd == "show" then
		xsadb.showAll()
	elseif kmnd == "delete" then
		xsadb.delete()
--	elseif kmnd == "sort" then
--		table.sort(db)
	elseif kmnd == "help" then
		print("\n\27[32m\27[1mXSADB: Help System")
		print("-------------------\27[0m")
		print("\27[32mshow\27[0m    - List all database")
		print("\27[32mset\27[0m     - Set into database")
		print("\27[32mdelete\27[0m  - Delete from database")
		print("\27[32msearch\27[0m  - Search for value (case insensitive)")
--		print("\27[32msort\27[0m    - Sort the database")
		print("\27[32mhelp\27[0m    - Show this screen")
		print("\27[32mversion\27[0m - Display XSADB Version")
		print("\27[32mexit\27[0m    - Exit the application\27[0m")
	elseif kmnd == "version" then
		print("\27[32mXSADB Version:\27[0m " .. version)
	else
		print("\27[31mUnknown Command\27[0m")
	end
	io.write("\n#! ")
	kmnd = io.read()
end

print("\27[32m\nXSADB Status:\27[0m      Saving Database.")

os.remove(filename)
fp = io.open(filename, "w")
if fp ~= nil then
	for k,v in ipairs(db) do
		fp:write(v .. "\n")
	end
	fp:close()
end

print("\27[32mXSADB Status: \27[0m     Save Complete.\n")
