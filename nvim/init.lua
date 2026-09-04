vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- Set Python host for Molten/Jupyter plugins
vim.g.python3_host_prog = vim.fn.expand '~/.neovim-venv/bin/python'
vim.g.have_nerd_font = false

-- UI & Display
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.o.signcolumn = 'yes'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.pumheight = 15
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Behavior
vim.o.clipboard = 'unnamedplus'
vim.o.undofile = true
vim.o.confirm = true
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.inccommand = 'split'

-- Search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Indentation & Wrapping
vim.o.expandtab = false
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.breakindent = true

local map = vim.keymap.set

-- Basic utilities
map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlights' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Window navigation
map('n', '<C-h>', '<C-w><C-h>', { desc = 'Focus left window' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Focus right window' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Focus lower window' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Focus upper window' })

-- Window resizing
map({ 'n', 'x' }, '<C-w>,', ':vertical resize -2<CR>', { silent = true, desc = 'Decrease window width' })
map({ 'n', 'x' }, '<C-w>.', ':vertical resize +2<CR>', { silent = true, desc = 'Increase window width' })
map({ 'n', 'x' }, '<C-w>-', ':resize -2<CR>', { silent = true, desc = 'Decrease window height' })
map({ 'n', 'x' }, '<C-w>=', ':resize +2<CR>', { silent = true, desc = 'Increase window height' })

-- Buffer navigation
map('n', '<Tab>', '<cmd>e #<CR>', { desc = 'Toggle last buffer' })
map({ 'n', 'x' }, '<leader>bd', '<cmd>:bd<CR>', { desc = 'Close buffer' })
map({ 'n', 'x' }, '<leader>bB', '<cmd>:bd!<CR>', { desc = 'Force close buffer' })

-- Editing QoL
map('n', 'J', 'mzJ`z', { desc = 'Join lines and keep cursor position' })
map('v', '<', '<gv', { desc = 'Indent left and reselect' })
map('v', '>', '>gv', { desc = 'Indent right and reselect' })

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Highlight text on yank
autocmd('TextYankPost', {
  group = augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank { timeout = 40 }
  end,
})

-- Jump to last position when opening a file
autocmd('BufReadPost', {
  group = augroup('jump-last-pos', { clear = true }),
  callback = function(args)
    local valid_line = vim.fn.line [['"]] >= 1 and vim.fn.line [['"]] < vim.fn.line '$'
    local not_commit = vim.b[args.buf].filetype ~= 'commit'
    if valid_line and not_commit then
      vim.cmd [[normal! g`"]]
    end
  end,
})

-- Map 'q' to close help/quickfix windows easily
autocmd('FileType', {
  group = augroup('close-with-q', { clear = true }),
  pattern = 'help,qf,netrw',
  callback = function()
    vim.keymap.set('n', 'q', '<C-w>c', { buffer = true })
  end,
})

-- Better markdown viewing
autocmd('FileType', {
  group = augroup('markdown-view', { clear = true }),
  pattern = 'markdown',
  callback = function()
    vim.opt_local.conceallevel = 0
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
  end,
})

-- Install lazy.nvim if missing
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Configure plugins
require('lazy').setup {
  -- Theme
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    opts = { integrations = { zen_mode = true } },
    init = function()
      vim.cmd.colorscheme 'catppuccin'
    end,
  },

  -- File Navigation: Oil & Telescope
  {
    'stevearc/oil.nvim',
    opts = {},
    keys = {
      { '-', '<cmd>Oil<cr>', desc = 'Open parent directory' },
    },
  },
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      'nvim-telescope/telescope-ui-select.nvim',
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      local telescope = require 'telescope'
      local builtin = require 'telescope.builtin'

      telescope.setup {
        extensions = {
          ['ui-select'] = { require('telescope.themes').get_dropdown() },
        },
      }
      pcall(telescope.load_extension, 'fzf')
      pcall(telescope.load_extension, 'ui-select')

      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Existing buffers' })
    end,
  },

  -- Git signs & navigation
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        local gs = require 'gitsigns'
        local function map_gs(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        map_gs('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gs.nav_hunk 'next'
          end
        end, 'Next Hunk')
        map_gs('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gs.nav_hunk 'prev'
          end
        end, 'Prev Hunk')
        map_gs('n', '<leader>hs', gs.stage_hunk, 'Stage Hunk')
        map_gs('n', '<leader>hr', gs.reset_hunk, 'Reset Hunk')
        map_gs('n', '<leader>hp', gs.preview_hunk, 'Preview Hunk')
      end,
    },
  },

  -- Editing Utilities
  { 'windwp/nvim-autopairs', event = 'InsertEnter', config = true },
  { 'folke/which-key.nvim', event = 'VimEnter', opts = { delay = 0 } },
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },
  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },

  -- Formatting
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      formatters_by_ft = { lua = { 'stylua' } },
    },
  },

  -- Treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- LSP, Completion, and Tooling
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = { { path = '${3rd}/luv/library', words = { 'vim%.uv' } } },
    },
  },
  {
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
    opts = {
      settings = {
        tsserver_format_options = { indentSize = 2, tabSize = 2, convertTabsToSpaces = true },
        tsserver_file_preferences = { includeInlayParameterNameHints = 'all' },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      local servers = {
        clangd = {},
        gopls = {},
        lua_ls = {
          settings = {
            Lua = { completion = { callSnippet = 'Replace' } },
          },
        },
      }

      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, { 'stylua' })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },
  {
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      { 'L3MON4D3/LuaSnip', version = '2.*' },
      'folke/lazydev.nvim',
    },
    opts = {
      keymap = { preset = 'default' },
      appearance = { nerd_font_variant = 'mono' },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev' },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'lua' },
      signature = { enabled = true },
    },
  },

  -- Notebook & REPL Workflow
  {
    'goerz/jupytext.vim',
    init = function()
      vim.g.jupytext_fmt = 'md'
      vim.g.jupytext_print_time = 0
    end,
  },
  {
    'benlubas/molten-nvim',
    version = '^1.0.0',
    build = ':UpdateRemotePlugins',
    init = function()
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_image_provider = 'none'
    end,
    keys = {
      { '<leader>mi', ':MoltenInit<CR>', desc = 'Initialize Molten' },
      { '<leader>e', ':MoltenEvaluateOperator<CR>', desc = 'Evaluate operator' },
      { '<leader>rl', ':MoltenEvaluateLine<CR>', desc = 'Evaluate line' },
      { '<leader>rc', ':MoltenReevaluateCell<CR>', desc = 'Re-evaluate cell' },
      { '<leader>rd', ':MoltenDelete<CR>', desc = 'Delete Molten cell output' },
      { '<leader>r', ':<C-u>MoltenEvaluateVisual<CR>gv', mode = 'v', desc = 'Evaluate visual selection' },
    },
  },
}
