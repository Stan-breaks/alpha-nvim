-- Originally authored by @AdamWhittingham, modified for a more compact and prettier look

local path_ok, plenary_path = pcall(require, "plenary.path")
if not path_ok then
    return
end

local dashboard = require("alpha.themes.dashboard")
local cdir = vim.fn.getcwd()
local if_nil = vim.F.if_nil

-- Configuration
local nvim_web_devicons = { enabled = true, highlight = true }
local mru_opts = {
    ignore = function(path, ext)
        return (string.find(path, "COMMIT_EDITMSG")) or (vim.tbl_contains({ "gitcommit" }, ext))
    end,
    autocd = false,
}

-- Helper functions
local function get_extension(fn)
    return fn:match("^.+(%..+)$") or ""
end

local function icon(fn)
    local nwd = require("nvim-web-devicons")
    local ext = get_extension(fn)
    return nwd.get_icon(fn, ext, { default = true })
end

local function file_button(fn, sc, short_fn, autocd)
    short_fn = short_fn or fn
    local ico_txt = nvim_web_devicons.enabled and (icon(fn) .. "  ") or ""
    local fb_hl = {}

    local cd_cmd = autocd and " | cd %:p:h" or ""
    local file_button_el =
        dashboard.button(sc, ico_txt .. short_fn, "<cmd>e " .. vim.fn.fnameescape(fn) .. cd_cmd .. " <CR>")

    local fn_start = short_fn:match(".*[/\\]")
    if fn_start then
        table.insert(fb_hl, { "Comment", #ico_txt - 2, #fn_start + #ico_txt })
    end

    file_button_el.opts.hl = fb_hl
    return file_button_el
end

local function mru(start, cwd, items_number, opts)
    opts = opts or mru_opts
    items_number = if_nil(items_number, 5) -- Reduced from 10 to 5 for compactness

    local oldfiles = {}
    for _, v in pairs(vim.v.oldfiles) do
        if #oldfiles == items_number then
            break
        end
        local cwd_cond = not cwd or vim.startswith(v, cwd)
        local ignore = opts.ignore and opts.ignore(v, get_extension(v)) or false
        if (vim.fn.filereadable(v) == 1) and cwd_cond and not ignore then
            table.insert(oldfiles, v)
        end
    end

    local tbl = {}
    for i, fn in ipairs(oldfiles) do
        local short_fn = cwd and vim.fn.fnamemodify(fn, ":.") or vim.fn.fnamemodify(fn, ":~")
        local file_button_el = file_button(fn, tostring(i + start - 1), short_fn, opts.autocd)
        table.insert(tbl, file_button_el)
    end

    return { type = "group", val = tbl, opts = {} }
end

-- Components
local header = {
    type = "text",
    val = {
        [[   ⣴⣶⣤⡤⠦⣤⣀⣤⠆     ⣈⣭⣭⣿⣶⣿⣦⣼⣆         ]],
        [[    ⠉⠻⢿⣿⠿⣿⣿⣶⣦⠤⠄⡠⢾⣿⣿⡿⠋⠉⠉⠻⣿⣿⡛⣦       ]],
        [[          ⠈⢿⣿⣟⠦ ⣾⣿⣿⣷⠄⠄⠄⠄⠻⠿⢿⣿⣧⣄     ]],
        [[           ⣸⣿⣿⢧ ⢻⠻⣿⣿⣷⣄⣀⠄⠢⣀⡀⠈⠙⠿⠄    ]],
        [[          ⢠⣿⣿⣿⠈  ⠡⠌⣻⣿⣿⣿⣿⣿⣿⣿⣛⣳⣤⣀⣀   ]],
        [[   ⢠⣧⣶⣥⡤⢄ ⣸⣿⣿⠘⠄ ⢀⣴⣿⣿⡿⠛⣿⣿⣧⠈⢿⠿⠟⠛⠻⠿⠄  ]],
        [[  ⣰⣿⣿⠛⠻⣿⣿⡦⢹⣿⣷   ⢊⣿⣿⡏  ⢸⣿⣿⡇ ⢀⣠⣄⣾⠄   ]],
        [[ ⣠⣿⠿⠛⠄⢀⣿⣿⣷⠘⢿⣿⣦⡀ ⢸⢿⣿⣿⣄ ⣸⣿⣿⡇⣪⣿⡿⠿⣿⣷⡄  ]],
        [[ ⠙⠃   ⣼⣿⡟  ⠈⠻⣿⣿⣦⣌⡇⠻⣿⣿⣷⣿⣿⣿ ⣿⣿⡇⠄⠛⠻⢷⣄ ]],
        [[      ⢻⣿⣿⣄   ⠈⠻⣿⣿⣿⣷⣿⣿⣿⣿⣿⡟ ⠫⢿⣿⡆     ]],
        [[       ⠻⣿⣿⣿⣿⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⡟⢀⣀⣤⣾⡿⠃     ]],
    },
    opts = {
        position = "center",
        hl = "Type",
    },
}

local function button(sc, txt, keybind)
    local sc_ = sc:gsub("%s", ""):gsub("SPC", "<leader>")
    local opts = {
        position = "center",
        text = txt,
        shortcut = sc,
        cursor = 3,
        width = 38,
        align_shortcut = "right",
        hl_shortcut = "Keyword",
    }
    if keybind then
        opts.keymap = { "n", sc_, keybind, { noremap = true, silent = true } }
    end
    return {
        type = "button",
        val = txt,
        on_press = function()
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keybind, true, false, true), "normal", false)
        end,
        opts = opts,
    }
end

local buttons = {
    type = "group",
    val = {
        button("e", "  New file", "<cmd>ene<CR>"),
        button("SPC f f", "󰈞  Find file", "<cmd>Telescope find_files<CR>"),
        button("SPC f g", "󰊄  Live grep", "<cmd>Telescope live_grep<CR>"),
        button("c", "  Configuration", "<cmd>cd ~/.config/nvim/ <CR>"),
        button("u", "  Update plugins", "<cmd>Lazy sync<CR>"),
        button("q", "󰅚  Quit", "<cmd>qa<CR>"),
    },
    opts = {
        spacing = 1,
    },
}

-- Main configuration
local config = {
    layout = {
        { type = "padding", val = 1 },
        header,
        { type = "padding", val = 1 },
        {
            type = "text",
            val = "Recent files",
            opts = { hl = "SpecialComment", position = "center" },
        },
        { type = "padding", val = 1 },
        {
            type = "group",
            val = function()
                return { mru(0, cdir) }
            end,
            opts = { shrink_margin = false },
        },
        { type = "padding", val = 1 },
        buttons,
    },
    opts = {
        margin = 1,
        setup = function()
            vim.api.nvim_create_autocmd("DirChanged", {
                pattern = "*",
                group = "alpha_temp",
                callback = function()
                    require("alpha").redraw()
                    vim.cmd("AlphaRemap")
                end,
            })
        end,
    },
}

-- Return the module
return {
    header = header,
    buttons = buttons,
    mru = mru,
    config = config,
    mru_opts = mru_opts,
    leader = dashboard.leader,
    nvim_web_devicons = nvim_web_devicons,
}
