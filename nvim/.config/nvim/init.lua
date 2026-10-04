--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

What is Kickstart?

  Kickstart.nvim is *not* a distribution.

  Kickstart.nvim is a starting point for your own configuration.
    The goal is that you can read every line of code, top-to-bottom, understand
    what your configuration is doing, and modify it to suit your needs.

  Once you've done that, you can start exploring, configuring and tinkering to
  make Neovim your own!

  If you don't know anything about Lua, I recommend taking some time to read through
  a guide. One possible example which will only take 10-15 minutes:
    - https://learnxinyminutes.com/docs/lua/

  After understanding a bit more about Lua, you can use `:help lua-guide` as a
  reference for how Neovim integrates Lua.
  - :help lua-guide
  - (or HTML version): https://neovim.io/doc/user/lua-guide.html

Kickstart Guide:

  TODO: The very first thing you should do is to run the command `:Tutor` in Neovim.

    If you don't know what this means, type the following:
      - <escape key>
      - :
      - Tutor
      - <enter key>

    (If you already know the Neovim basics, you can skip this step.)

  Once you've completed that, you can continue working through **AND READING** the rest
  of the kickstart init.lua.

If you experience any errors while trying to install kickstart, run `:checkhealth` for more info.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now! :)
--]]

-- ============================================================
-- SECTION 1: FOUNDATION
-- Core Neovim settings, leaders, options, basic keymaps, basic autocmds
-- ============================================================
do
  vim.loader.enable()

  -- Space is the leader key. Must be set before plugins load.
  -- <leader> means: press Space, then the next key(s)
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  -- We have JetBrainsMono Nerd Font installed and configured in Alacritty.
  -- This enables icons in neo-tree, lualine, bufferline, etc.
  vim.g.have_nerd_font = true

  -- [[ Options ]]
  -- See `:help vim.o` for all available options

  vim.o.number = true
  vim.o.relativenumber = true   -- Relative numbers: jump 5 lines with 5j, 5k

  vim.o.mouse = 'a'
  vim.o.showmode = false        -- Mode shown in lualine, not the command line

  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)  -- System clipboard

  vim.o.breakindent = true
  vim.o.undofile = true         -- Persistent undo across sessions

  vim.o.ignorecase = true
  vim.o.smartcase = true        -- Case-sensitive only when uppercase is typed

  vim.o.signcolumn = 'yes'      -- Always show, avoids layout shift on diagnostics

  vim.o.updatetime = 250
  vim.o.timeoutlen = 300

  vim.o.splitright = true       -- New vertical split opens to the right
  vim.o.splitbelow = true       -- New horizontal split opens below

  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

  vim.o.inccommand = 'split'    -- Live preview for substitutions
  vim.o.cursorline = true       -- Highlight the line the cursor is on
  vim.o.scrolloff = 8           -- Keep 8 lines visible above/below cursor
  vim.o.confirm = true

  -- Indentation: 4 spaces, no hard tabs
  vim.o.tabstop = 4
  vim.o.shiftwidth = 4
  vim.o.expandtab = true
  vim.o.smartindent = true

  vim.o.wrap = false            -- No line wrapping

  -- [[ Keymaps ]]
  -- See `:help vim.keymap.set()`
  -- Format: keymap.set(mode, key, action, { desc = 'description' })
  -- The desc field is what shows up in which-key when you press leader and wait.

  -- Clear search highlights when pressing Escape in normal mode
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  -- Diagnostic navigation
  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },
    virtual_text = true,
    virtual_lines = false,
    jump = {
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float {
          bufnr = bufnr,
          scope = 'cursor',
          focus = false,
        }
      end,
    },
  }

  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

  -- Exit terminal mode with Esc Esc (default Ctrl+\ Ctrl+n is hard to remember)
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  -- Window navigation with Ctrl+hjkl
  -- vim-tmux-navigator extends this so Ctrl+hjkl works across tmux panes too
  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  -- Save with Ctrl+S (familiar from other editors)
  vim.keymap.set('n', '<C-s>', '<cmd>w<CR>', { desc = 'Save file' })
  vim.keymap.set('i', '<C-s>', '<Esc><cmd>w<CR>a', { desc = 'Save file (insert mode)' })

  -- Buffer navigation: Shift+H/L to move between open files
  vim.keymap.set('n', '<S-h>', '<cmd>bprevious<CR>', { desc = 'Previous buffer' })
  vim.keymap.set('n', '<S-l>', '<cmd>bnext<CR>', { desc = 'Next buffer' })
  vim.keymap.set('n', '<leader>x', '<cmd>bdelete<CR>', { desc = 'Close current buffer' })

  -- Run current Python file with Space + r
  vim.keymap.set("n", "<leader>r", ":w<CR>:!python %<CR>", 
  { desc = "Run current file" })
  
  -- Window splits
  vim.keymap.set('n', '<leader>sv', '<cmd>vsplit<CR>', { desc = '[S]plit [V]ertical' })
  vim.keymap.set('n', '<leader>sh', '<cmd>split<CR>', { desc = '[S]plit [H]orizontal' })

  -- Move selected lines up/down in visual mode
  -- After moving, re-select and re-indent with gv=gv
  vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
  vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

  -- [[ Autocommands ]]
  -- Highlight yanked (copied) text briefly — visual feedback
  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })
end

-- ============================================================
-- SECTION 2: PLUGIN MANAGER INTRO
-- vim.pack — Neovim's built-in plugin manager (added in 0.12)
-- No third-party plugin manager needed.
-- ============================================================
do
  -- vim.pack.add installs plugins from git URLs.
  -- To update all plugins: :lua vim.pack.update()
  -- To check status: :lua vim.pack.update(nil, { offline = true })

  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then output = 'No output from build command.' end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then return end

      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
        return
      end

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })
end

---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- ============================================================
-- SECTION 3: UI / CORE UX PLUGINS
-- Colorscheme, statusline, bufferline, dashboard, gitsigns,
-- which-key, todo-comments, mini modules
-- ============================================================
do
  -- guess-indent: auto-detects indentation style of files you open
  vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
  require('guess-indent').setup {}

  -- nvim-web-devicons: file icons (requires Nerd Font — enabled above)
  if vim.g.have_nerd_font then vim.pack.add { gh 'nvim-tree/nvim-web-devicons' } end

  -- gitsigns: shows git diff markers in the gutter (left edge)
  -- + = added line, ~ = modified line, _ = deleted line
  vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
  require('gitsigns').setup {
    signs = {
      add = { text = '+' }, ---@diagnostic disable-line: missing-fields
      change = { text = '~' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },
  }

  -- which-key: shows available keybinds when you pause after pressing a key
  -- Press <leader> and wait — a popup shows all leader bindings
  vim.pack.add { gh 'folke/which-key.nvim' }
  require('which-key').setup {
    delay = 0,
    icons = { mappings = vim.g.have_nerd_font },
    spec = {
      { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      { '<leader>g', group = '[G]it' },
      { 'gr', group = 'LSP Actions', mode = { 'n' } },
    },
  }

  -- [[ Colorscheme: Catppuccin Frappe ]]
  -- Frappe matches the tmux catppuccin-frappe theme already configured.
  -- transparent_background lets Hyprland/Alacritty's blur and opacity show through.
  vim.pack.add { gh 'catppuccin/nvim' }
  require('catppuccin').setup {
    name = 'catppuccin',
    flavour = 'frappe',
    transparent_background = true,
    integrations = {
      gitsigns = true,
      treesitter = true,
      telescope = { enabled = true },
      indent_blankline = { enabled = true },
      native_lsp = { enabled = true },
      mini = { enabled = true },
      bufferline = true,
    },
  }
  vim.cmd.colorscheme 'catppuccin'

  -- todo-comments: highlights TODO, FIXME, HACK, NOTE, etc. in code
  -- Also lets you search all TODOs in the project via Telescope
  vim.pack.add { gh 'folke/todo-comments.nvim' }
  require('todo-comments').setup { signs = false }

  -- [[ mini.nvim ]]
  -- A collection of small independent modules. Using: mini.ai and mini.surround.
  vim.pack.add { gh 'nvim-mini/mini.nvim' }

  -- mini.ai: better text objects
  -- Examples: va) = select around paren, ci' = change inside quote
  require('mini.ai').setup {
    mappings = {
      around_next = 'aa',
      inside_next = 'ii',
    },
    n_lines = 500,
  }

  -- mini.surround: add/change/delete surrounding characters
  -- saiw) = surround word with (), sd' = delete surrounding ', sr)' = replace ) with '
  require('mini.surround').setup()

  -- [[ Lualine: status bar at the bottom ]]
  -- Shows: vim mode, git branch, file name, diagnostics, file type, cursor position
  vim.pack.add { gh 'nvim-lualine/lualine.nvim' }
  require('lualine').setup {
    options = {
      theme = 'catppuccin-frappe',
      component_separators = { left = '', right = '' },
      section_separators = { left = '', right = '' },
    },
  }

  -- [[ Bufferline: tabs at the top for open buffers ]]
  -- Shift+H/L to navigate, <leader>x to close (defined in Section 1)
  vim.pack.add { gh 'akinsho/bufferline.nvim' }
  -- catppuccin bufferline integration: only available after catppuccin is installed.
  -- pcall prevents a crash on the very first launch when the plugin is still downloading.
  local bufferline_highlights = {}
  local ok, catppuccin_bl = pcall(require, 'catppuccin.groups.integrations.bufferline')
  if ok then
    bufferline_highlights = catppuccin_bl.get { styles = { 'bold' } }
  end
  require('bufferline').setup {
    highlights = bufferline_highlights,
    options = {
      diagnostics = 'nvim_lsp',
      offsets = {
        { filetype = 'neo-tree', text = 'File Explorer', text_align = 'center' },
      },
      separator_style = 'slant',
    },
  }

  -- [[ Alpha: dashboard shown when nvim opens without a file ]]
  -- Press the shortcut letter to run the action
  vim.pack.add { gh 'goolord/alpha-nvim' }
  local alpha = require 'alpha'
  local dashboard = require 'alpha.themes.dashboard'
  dashboard.section.header.val = {
    '                                                     ',
    '  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗',
    '  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║',
    '  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║',
    '  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║',
    '  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║',
    '  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝',
  }
  dashboard.section.buttons.val = {
    dashboard.button('f', '  Find file',     '<cmd>Telescope find_files<CR>'),
    dashboard.button('r', '  Recent files',  '<cmd>Telescope oldfiles<CR>'),
    dashboard.button('g', '  Find text',     '<cmd>Telescope live_grep<CR>'),
    dashboard.button('c', '  Config',        '<cmd>e $MYVIMRC<CR>'),
    dashboard.button('q', '  Quit',          '<cmd>qa<CR>'),
  }
  alpha.setup(dashboard.config)

  -- neoscroll: smooth animated scrolling instead of instant jumps
  vim.pack.add { gh 'karb94/neoscroll.nvim' }
  require('neoscroll').setup { easing = 'quadratic' }
end

-- ============================================================
-- SECTION 4: SEARCH & NAVIGATION
-- Telescope fuzzy finder + keymaps
-- ============================================================
do
  ---@type (string|vim.pack.Spec)[]
  local telescope_plugins = {
    gh 'nvim-lua/plenary.nvim',
    gh 'nvim-telescope/telescope.nvim',
    gh 'nvim-telescope/telescope-ui-select.nvim',
  }
  if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

  vim.pack.add(telescope_plugins)

  require('telescope').setup {
    extensions = {
      ['ui-select'] = { require('telescope.themes').get_dropdown() },
    },
  }

  pcall(require('telescope').load_extension, 'fzf')
  pcall(require('telescope').load_extension, 'ui-select')

  local builtin = require 'telescope.builtin'
  vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
  vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
  vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
  vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

  -- LSP-specific pickers — activated when a language server attaches to a buffer
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event)
      local buf = event.buf
      vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
      vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
      vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
      vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
      vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })
      vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
    end,
  })

  vim.keymap.set('n', '<leader>/', function()
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end, { desc = '[/] Fuzzily search in current buffer' })

  vim.keymap.set('n', '<leader>s/', function()
    builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' }
  end, { desc = '[S]earch [/] in Open Files' })

  vim.keymap.set('n', '<leader>sn', function()
    builtin.find_files { cwd = vim.fn.stdpath 'config' }
  end, { desc = '[S]earch [N]eovim files' })
end

-- ============================================================
-- SECTION 5: LSP
-- Language servers, Mason (LSP installer), formatting
-- ============================================================
do
  -- fidget: shows LSP loading progress in the bottom-right corner
  vim.pack.add { gh 'j-hui/fidget.nvim' }
  require('fidget').setup {}

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
      map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
      map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })
        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      if client and client:supports_method('textDocument/inlayHint', event.buf) then
        map('<leader>th', function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
        end, '[T]oggle Inlay [H]ints')
      end
    end,
  })

  -- [[ Language Servers ]]
  -- Each entry here will be auto-installed by Mason and started automatically.
  -- Add/remove servers as needed. Run :Mason to manage manually.
  ---@type table<string, vim.lsp.Config>
  local servers = {
    -- Lua (especially useful for editing this nvim config itself)
    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false
        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
        end
        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
          runtime = { version = 'LuaJIT', path = { 'lua/?.lua', 'lua/?/init.lua' } },
          workspace = {
            checkThirdParty = false,
            library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
              '${3rd}/luv/library',
              '${3rd}/busted/library',
            }),
          },
        })
      end,
      settings = { Lua = { format = { enable = false } } },
    },

    pyright = {},    -- Python
    ts_ls = {},      -- TypeScript / JavaScript
    html = {},       -- HTML
    cssls = {},      -- CSS
    jsonls = {},     -- JSON
    bashls = {},     -- Bash scripts
    clangd = {},     -- C / C++
    marksman = {},   -- Markdown

    -- Formatters (not LSPs, but Mason installs them the same way)
    stylua = {},     -- Lua formatter
  }

  vim.pack.add {
    gh 'neovim/nvim-lspconfig',
    gh 'mason-org/mason.nvim',
    gh 'mason-org/mason-lspconfig.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  }

  require('mason').setup {}

  local ensure_installed = vim.tbl_keys(servers or {})
  vim.list_extend(ensure_installed, {
    'prettier',  -- JS/TS/HTML/CSS/JSON formatter
    'black',     -- Python formatter
  })

  require('mason-tool-installer').setup { ensure_installed = ensure_installed }

  for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end
end

-- ============================================================
-- SECTION 6: FORMATTING
-- conform.nvim: format on demand or on save
-- ============================================================
do
  vim.pack.add { gh 'stevearc/conform.nvim' }
  require('conform').setup {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- Add filetypes here to enable format-on-save for them
      local enabled_filetypes = {
        -- lua = true,
        -- python = true,
      }
      if enabled_filetypes[vim.bo[bufnr].filetype] then
        return { timeout_ms = 500 }
      else
        return nil
      end
    end,
    default_format_opts = { lsp_format = 'fallback' },
    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'black' },
      javascript = { 'prettier', stop_after_first = true },
      typescript = { 'prettier', stop_after_first = true },
      html = { 'prettier' },
      css = { 'prettier' },
      json = { 'prettier' },
      markdown = { 'prettier' },
    },
  }

  -- <leader>f to format the current buffer (or selection in visual mode)
  vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
    require('conform').format { async = true }
  end, { desc = '[F]ormat buffer' })
end

-- ============================================================
-- SECTION 7: AUTOCOMPLETE & SNIPPETS
-- blink.cmp (completion engine) + LuaSnip (snippets)
-- ============================================================
do
  vim.pack.add { { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' } }
  require('luasnip').setup {}

  -- blink.cmp: modern completion engine
  -- In insert mode: Ctrl+N/P to navigate, Ctrl+Y to accept, Ctrl+E to close
  vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
  require('blink.cmp').setup {
    keymap = { preset = 'default' },
    appearance = { nerd_font_variant = 'mono' },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 300 },
    },
    sources = { default = { 'lsp', 'path', 'snippets' } },
    snippets = { preset = 'luasnip' },
    fuzzy = { implementation = 'lua' },
    signature = { enabled = true },
  }
end

-- ============================================================
-- SECTION 8: TREESITTER
-- Advanced syntax highlighting and code-aware features
-- ============================================================
do
  vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

  -- Parsers to install automatically.
  -- Treesitter uses language-specific parsers to understand code structure.
  -- This enables accurate highlighting, indentation, and text objects.
  local parsers = {
    'bash', 'c', 'cpp', 'css', 'diff', 'html',
    'javascript', 'json', 'lua', 'luadoc',
    'markdown', 'markdown_inline', 'python',
    'query', 'toml', 'typescript', 'vim', 'vimdoc', 'yaml',
  }
  require('nvim-treesitter').install(parsers)

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    if not vim.treesitter.language.add(language) then return end
    vim.treesitter.start(buf, language)
    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil
    if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match
      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end
      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'
      if vim.tbl_contains(installed_parsers, language) then
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        treesitter_try_attach(buf, language)
      end
    end,
  })
end

-- ============================================================
-- SECTION 9: ADDITIONAL PLUGINS
-- File explorer, git UI, tmux integration, and more
-- ============================================================
do
  -- [[ Neo-tree: file explorer sidebar ]]
  -- <leader>e to toggle, \ to reveal current file
  require 'kickstart.plugins.neo-tree'
  vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle<CR>', { desc = 'Toggle file [E]xplorer' })

  -- [[ Autopairs: auto-closes brackets, quotes, parens as you type ]]
  require 'kickstart.plugins.autopairs'

  -- [[ Indent blankline: visual indent guides ]]
  require 'kickstart.plugins.indent_line'

  -- [[ Lazygit: full git UI inside Neovim ]]
  -- <leader>gg opens lazygit in a floating window
  -- requires lazygit installed in the system (installed in Section 1)
  vim.pack.add { gh 'kdheepak/lazygit.nvim' }
  vim.keymap.set('n', '<leader>gg', '<cmd>LazyGit<CR>', { desc = 'Open [G]it UI (lazygit)' })

  -- [[ vim-tmux-navigator: seamless navigation between nvim splits and tmux panes ]]
  -- Ctrl+h/j/k/l now works whether you're in nvim or tmux — no more prefix needed
  -- Matches the vim-tmux-navigator plugin already installed in ~/.config/tmux/
  vim.pack.add { gh 'christoomey/vim-tmux-navigator' }
end

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
