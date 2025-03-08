local json = require("json")
local config = json.decode(LoadResourceFile(GetCurrentResourceName(), "config.json"))

local availableHouses = config.availableHouses

-- Ensure the database schema is correct
exports.oxmysql:execute([[
    CREATE TABLE IF NOT EXISTS houses (
        postal VARCHAR(255) PRIMARY KEY,
        owner VARCHAR(255),
        purchasedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
]], {}, function(result)
    if result.warningCount == 0 then
        print("Database schema validated successfully.")
    else
        print("Warning: Issues detected while validating database schema.")
    end
end)

-- Function to get player's CFX name
local function getPlayerName(src)
    return GetPlayerName(src) or "Unknown"
end

-- Function to check if a postal is valid
local function isValidPostal(postal)
    for _, v in ipairs(availableHouses) do
        if v == postal then
            return true
        end
    end
    return false
end

-- Function to check if a player has keys to a house
local function hasKeys(playerName, postal, callback)
    exports.oxmysql:execute("SELECT owner FROM houses WHERE postal = ?", {postal}, function(result)
        if result[1] and result[1].owner == playerName then
            callback(true)
            return
        end
        
        exports.oxmysql:execute("SELECT owner FROM house_keys WHERE postal = ? AND owner = ?", {postal, playerName}, function(sharedResult)
            callback(sharedResult[1] ~= nil)
        end)
    end)
end

-- Command to list all houses and their status
RegisterCommand("listhouses", function(source, args, rawCommand)
    local src = source
    local houseStatus = {}

    exports.oxmysql:execute("SELECT postal, owner FROM houses", {}, function(result)
        local ownedPostals = {}
        for _, row in pairs(result) do
            ownedPostals[row.postal] = row.owner
        end

        for _, postal in ipairs(availableHouses) do
            if ownedPostals[postal] then
                table.insert(houseStatus, postal .. " - Owned by " .. ownedPostals[postal])
            else
                table.insert(houseStatus, postal .. " - Available for purchase")
            end
        end

        TriggerClientEvent("notifyPlayer", src, "House Market:\n" .. table.concat(houseStatus, "\n"))
    end)
end, false)

-- Buy House Command (with additional owner)
RegisterCommand("buyhouse", function(source, args, rawCommand)
    local src = source
    local postal = args[1]
    local playerName = getPlayerName(src)
    local cfxName = args[2]  -- Second argument for additional owner's CFX name

    if not postal or not isValidPostal(postal) then
        TriggerClientEvent("notifyPlayer", src, "Invalid house! Use /listhouses to check available properties.")
        return
    end

    exports.oxmysql:execute("SELECT owner FROM houses WHERE postal = ?", {postal}, function(result)
        if result[1] then
            TriggerClientEvent("notifyPlayer", src, "This house is already owned by " .. result[1].owner)
        else
            -- Insert primary owner (the current player)
            exports.oxmysql:execute("INSERT INTO houses (postal, owner, purchasedAt) VALUES (?, ?, NOW())", {postal, playerName}, function()
                -- Insert secondary owner (the additional player)
                if cfxName then
                    exports.oxmysql:execute("INSERT INTO house_owners (postal, owner_cfxname) VALUES (?, ?)", {postal, cfxName}, function()
                        TriggerClientEvent("notifyPlayer", src, "You successfully bought the house at postal " .. postal .. " and added " .. cfxName .. " as an additional owner!")
                    end)
                else
                    TriggerClientEvent("notifyPlayer", src, "You successfully bought the house at postal " .. postal .. "!")
                end
            end)
        end
    end)
end, false)

-- Sell House Command
RegisterCommand("sellhouse", function(source, args, rawCommand)
    local src = source
    local postal = args[1]
    local cfxName = args[2]  -- Second argument for additional owner's CFX name
    local playerName = getPlayerName(src)

    if not postal or not isValidPostal(postal) then
        TriggerClientEvent("notifyPlayer", src, "Invalid house! Use /listhouses to check available properties.")
        return
    end

    exports.oxmysql:execute("SELECT owner FROM houses WHERE postal = ?", {postal}, function(result)
        if not result[1] then
            TriggerClientEvent("notifyPlayer", src, "This house is not owned!")
        elseif result[1].owner ~= playerName then
            TriggerClientEvent("notifyPlayer", src, "You do not own this house!")
        else
            -- Remove house from the houses table
            exports.oxmysql:execute("DELETE FROM houses WHERE postal = ?", {postal}, function()
                if cfxName then
                    -- Check if the secondary owner exists before attempting to remove
                    exports.oxmysql:execute("SELECT owner_cfxname FROM house_owners WHERE postal = ? AND owner_cfxname = ?", {postal, cfxName}, function(sharedResult)
                        if sharedResult[1] then
                            -- Delete the secondary owner from house_owners table
                            exports.oxmysql:execute("DELETE FROM house_owners WHERE postal = ? AND owner_cfxname = ?", {postal, cfxName}, function()
                                TriggerClientEvent("notifyPlayer", src, "You successfully sold your house at postal " .. postal .. " and removed " .. cfxName .. " as an additional owner!")
                            end)
                        else
                            TriggerClientEvent("notifyPlayer", src, "No secondary owner found for " .. cfxName .. "!")
                        end
                    end)
                else
                    -- No secondary owner, just sell the house
                    TriggerClientEvent("notifyPlayer", src, "You successfully sold your house at postal " .. postal .. "!")
                end
            end)
        end
    end)
end, false)

-- List House Keys Command
RegisterCommand("listhousekeys", function(source, args, rawCommand)
    local src = source
    local postal = args[1]

    if not postal then
        TriggerClientEvent("notifyPlayer", src, "Usage: /listhousekeys [house postal]")
        return
    end

    exports.oxmysql:execute("SELECT owner FROM house_keys WHERE postal = ?", {postal}, function(result)
        local keysList = {}
        for _, row in ipairs(result) do
            table.insert(keysList, row.owner)
        end

        TriggerClientEvent("notifyPlayer", src, "House " .. postal .. " keys shared with: " .. table.concat(keysList, ", "))
    end)
end, false)
