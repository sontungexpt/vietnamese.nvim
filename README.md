# 🚀 Vietnamese.nvim – Vietnamese Input Engine for Neovim

**Vietnamese.nvim** giúp bạn gõ tiếng Việt dễ dàng trong Neovim, hỗ trợ logic xử lý dấu câu tự động, tương thích nhiều IME (ibus, fcitx5…), và tích hợp mượt với nhiều plugin khác.

## 🔧 Tính năng chính

- Gõ dấu **Telex**(dơn giản), **VNI** đúng vị trí, tự động điều chỉnh dấu cho từ hiện tại trên con trỏ.
- Tự động bật/tắt IME hệ thống khi focus/blur Neovim.
- Realtime xử lý dấu câu khi gõ
- Tương thích với plugin **bim** để xử lí việc mapping jj hay jk để escape
- Có thể chỉnh sửa từ đã gõ một cách dễ dàng hơn chỉ cần di chuyển tới vị trí từ đó rồi gõ các kí tự dấu thay vì phải xoá đi gõ lại như ime tryền thống

---

## 🖼️ Minh hoạ

- Mình viết file readme này bằng chính plugin này

## ⚙️ Cài đặt

### Dùng plugin manager (lua)

**Lazy.nvim:**

```lua
{
    "sontungexpt/vietnamese.nvim",
    dependencies = {
        -- if you want to map jj or any key to escape
        "sontungexpt/bim.nvim",
    },nvim-web-devicons
    event = "InsertEnter",
    config = function(
        require("vietnamese").setup()
    end,
}
```

**Packer.nvim:**

```lua
use {
    "sontungexpt/vietnamese.nvim",
    config = function()
        require("vietnamese").setup()
    end,
}

```

---

## 🧠 Cấu hình

Bạn có thể tùy chỉnh \`telex\`, \`vni\`, hoặc các nút xoá dấu trong file \`lua/vietnamese/config.lua\`. Ví dụ:

```lua
require("vietnamese").setup({
    enabled = true, -- Bật plugin
    input_method = "telex", -- Hoặc "vni" (hiện tại chỉ hỗ trợ telex đơn giản)
    excluded = {
        filetypes = {
            "nvimtree", -- Loại filetypes
            "help",
        }, -- File types to exclude
        buftypes = {
            "nowrite",
            "quickfix",
            "prompt",
        }, -- Loại buffer types
    },
    custom_methods = {}, -- Tự tạo riêng intput methods của mình
})

```

Command:

- VietnameseToggle: Bật/Tắt plugin
- VietnameseMethod: Chuyển đổi giữa các phương thức gõ dấu (telex, vni, hoặc custom methods)

---

## ⏱️ Cách hoạt động sơ lược

1. Khi ở chế độ Insert, plugin dùng \`vim.on_key()\` để theo dõi phím gõ nhưng **không** thao tác buffer luôn.
2. Đến event \`InsertCharPre\` hoặc \`TextChangedI\` — buffer đã ổn định — plugin lấy toàn chữ bên trái và phải dấu, xử lý dấu với \`WordEngine\`, và update đoạn từ.
3. Khi focus/blur window, plugin sẽ bật/tắt IME như **ibus**, **fcitx5**.
4. Ở đây mình không lưu lại buffer như các ime truyền thống mà mình sẽ xem mỗi một tử là một
   buffer và dựa vào api neovim để lấy buffer như vậy chúng ta có thể sửa từ đã gõ dễ dàng mà
   không cần xoá đi gõ lại

---

## ✅ NOTES

- Khuyến khích mọi người chuyển sang tiếng anh cho các IME hệ thống trước khi xài plugins,
  vì hiện tại mình chưa xử lí kĩ phần này

---

## 🧩 Phát triển & Góp ý

Rất hoan nghênh issue & pull request! Bạn có thể:

- Báo lỗi logic xử lý dấu hoặc tương thích IME.
- Gợi ý hỗ trợ thêm IME khác hoặc method mới.
- Xin thêm API hoặc thiết lập linh hoạt hơn.

---

## 📄 Giấy phép

Được phát hành với giấy phép **Apache Licence 2.0** – xem file [LICENSE](LICENSE)
