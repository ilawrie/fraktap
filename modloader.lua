-- ==========================================
-- MODULE LOADER SYSTEM
-- ==========================================
local ModuleLoader = {}

-- Таблица загруженных модулей
ModuleLoader.modules = {}

-- Функция для загрузки модуля
function ModuleLoader:Load(moduleName)
    if self.modules[moduleName] then
        return self.modules[moduleName]
    end

    local modulePath = script.Parent:FindFirstChild(moduleName)
    if not modulePath then
        error("Module not found: " .. moduleName)
    end

    local moduleScript = require(modulePath)
    self.modules[moduleName] = moduleScript
    return moduleScript
end

-- Функция для загрузки всех необходимых модулей
function ModuleLoader:LoadAll()
    local modules = {
        "autofarm",
        "autochest",
        "setanimal",
        "setkeeper",
        "killexploit",
        "killanimals",
        "destroyprops",
        "esp"
    }

    for _, moduleName in ipairs(modules) do
        pcall(function()
            self:Load(moduleName)
        end)
    end

    return self.modules
end

return ModuleLoader
