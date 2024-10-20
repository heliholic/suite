local fields = {}
local rows = {}
local cols = {}


local total_bytes = 16


-- generate rows
for i=0, total_bytes - 1 do
    rows[i + 1] = tostring(i)
end

cols = {"UINT8", "INT8"}


-- uint8 fields
for i=0, total_bytes - 1 do
    fields[#fields + 1] = {col=1, row=i + 1, min = 0, max = 255, vals = { #fields + 1 } }
end

-- int8 fields
for i=0, total_bytes - 1 do
    fields[#fields + 1] = {col=2, row=i + 1, min = 0, max = 255, vals = { #fields + 1 } }
end


local function postLoad(self)
    rfsuite.app.triggers.isReady = true
end

local function openPage(idx, title, script)

    rfsuite.app.uiState = rfsuite.app.uiStatus.pages
    rfsuite.app.triggers.isReady = false

    rfsuite.app.Page = assert(compile.loadScript(rfsuite.config.suiteDir .. "app/pages/" .. script))()


    rfsuite.app.lastIdx = idx
    rfsuite.app.lastTitle = title
    rfsuite.app.lastScript = script
    rfsuite.lastPage = script

    rfsuite.app.uiState = rfsuite.app.uiStatus.pages

    longPage = false

    form.clear()

    rfsuite.app.ui.fieldHeader(title)
    local numCols
    if rfsuite.app.Page.cols ~= nil then
        numCols = #rfsuite.app.Page.cols
    else
        numCols = 2
    end
    local screenWidth = rfsuite.config.lcdWidth - 10
    local padding = 10
    local paddingTop = rfsuite.app.radio.linePaddingTop
    local h = rfsuite.app.radio.navbuttonHeight
    local w = ((screenWidth * 50 / 100) / numCols)
    local paddingRight = 0
    local positions = {}
    local positions_r = {}
    local pos

    line = form.addLine("Byte")

    local loc = numCols
    local posX = screenWidth - paddingRight
    local posY = paddingTop

    local c = 1
    while loc > 0 do
        local colLabel = rfsuite.app.Page.cols[loc]

        positions[loc] = posX - w + paddingRight
        positions_r[c] = posX - w + paddingRight
        posX = math.floor(posX - w)

        pos = {x = positions[loc] + padding, y = posY, w = w, h = h}
        form.addStaticText(line, pos, colLabel)

        loc = loc - 1
        c = c + 1
    end

    -- display each row
    local byteRows = {}
    for ri, rv in ipairs(rfsuite.app.Page.rows) do byteRows[ri] = form.addLine(rv) end

    for i = 1, #rfsuite.app.Page.fields do
        local f = rfsuite.app.Page.fields[i]
        local l = rfsuite.app.Page.labels
        local pageIdx = i
        local currentField = i

        posX = positions[f.col]

        pos = {x = posX + padding, y = posY, w = w - padding, h = h}

        minValue = f.min * rfsuite.utils.decimalInc(f.decimals)
        maxValue = f.max * rfsuite.utils.decimalInc(f.decimals)
        if f.mult ~= nil then
            minValue = minValue * f.mult
            maxValue = maxValue * f.mult
        end

        rfsuite.app.formFields[i] = form.addNumberField(byteRows[f.row], pos, minValue, maxValue, function()
            local value = rfsuite.utils.getFieldValue(rfsuite.app.Page.fields[i])
            return value
        end, function(value)
            f.value = rfsuite.utils.saveFieldValue(rfsuite.app.Page.fields[i], value)
            rfsuite.app.saveValue(i)
        end)
        if f.default ~= nil then
            local default = f.default * rfsuite.utils.decimalInc(f.decimals)
            if f.mult ~= nil then default = default * f.mult end
            rfsuite.app.formFields[i]:default(default)
        else
            rfsuite.app.formFields[i]:default(0)
        end
        if f.decimals ~= nil then rfsuite.app.formFields[i]:decimals(f.decimals) end
        if f.unit ~= nil then rfsuite.app.formFields[i]:suffix(f.unit) end
        if f.help ~= nil then
            if rfsuite.app.fieldHelpTxt[f.help]['t'] ~= nil then
                local helpTxt = rfsuite.app.fieldHelpTxt[f.help]['t']
                rfsuite.app.formFields[i]:help(helpTxt)
            end
        end
    end

    rfsuite.app.triggers.closeProgressLoader = true

end



return {
    read =  158, -- MSP_EXPERIMENTAL
    write = 159, -- MSP_SET_EXPERIMENTAL
    title       = "Experimental",
    navButtons = {menu = true, save = true, reload = false, help = true},
    minBytes    = 0,
    eepromWrite = true,
    labels      = labels,
    fields      = fields,
    simulatorResponse = {},
    rows = rows,
    cols = cols,    
    openPage = openPage,
    postLoad = postLoad
}