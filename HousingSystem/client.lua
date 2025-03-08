RegisterNetEvent("notifyPlayer")
AddEventHandler("notifyPlayer", function(message)
    TriggerEvent("chat:addMessage", { args = { "^1[House System] ", message } })
end)
