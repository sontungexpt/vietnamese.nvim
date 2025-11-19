# 🚀 Vietnamese.nvim – Vietnamese Input Engine for Neovim

**Vietnamese.nvim** giúp bạn gõ tiếng Việt dễ dàng trong Neovim, hỗ trợ logic xử lý dấu câu tự động, tương thích nhiều IME (ibus, fcitx5…), và tích hợp mượt với nhiều plugin khác.

## 🔧 Tính năng chính

- Gõ dấu **Telex**(dơn giản), **VNI**, **VIQR** đúng vị trí, tự động điều chỉnh dấu cho từ hiện tại trên con trỏ.

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
            "sontungexpt/bim.nvim",
          },
          event = "InsertEnter",
          opts = {}
        },
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
    enabled = true,
    -- "old" | "modern"
    orthography = "modern", -- Default tone strategy
    input_method = "telex", -- Default input method
    excluded = {
        filetypes = {
            "nvimtree", -- File types to exclude
            "help",
        }, -- File types to exclude
        buftypes = {
            "nowrite",
            "quickfix",
            "prompt",
        }, -- Buffer types to excludek
    },
    custom_methods =
        -- Tự tạo riêng intput methods của mình
        -- Tạm thời mọi người đừng tự tạo bởi vì mình chưa test (này edge case nên để sau)
        -- Còn néu muôn tạo thì mọi người làm giống trong file config của telex là được

        name = {

            -- nhớ import ENUM_DIACRITIC from vietnamese.constant trên đầu file config để lấy enum

            -- local ENUM_DIACRITIC = require("vietnamese.util.codec").DIACRITIC

            tone_keys = {
                ["s"] = ENUM_DIACRITIC.Acute,
                ["f"] = ENUM_DIACRITIC.Grave,
                ["r"] = ENUM_DIACRITIC.Hook,
                ["x"] = ENUM_DIACRITIC.Tilde,
                ["j"] = ENUM_DIACRITIC.Dot,
            },
            tone_removal_keys = {
                ["z"] = true,
            },
            shape_keys = {
                w = {
                    a = ENUM_DIACRITIC.Breve,
                    o = ENUM_DIACRITIC.Horn,
                    u = ENUM_DIACRITIC.Horn,
                    e = ENUM_DIACRITIC.Circumflex,
                },

                a = {
                    a = ENUM_DIACRITIC.Circumflex,
                },

                e = {
                    e = ENUM_DIACRITIC.Circumflex,
                },

                o = {
                    o = ENUM_DIACRITIC.Circumflex,
                },

                d = {
                    d = ENUM_DIACRITIC.Stroke,
                },
            },

            -- Check if a character is a valid input character to make a Vietnamese character
            is_diacritic_pressed = function(char)
                return char:lower():match("[sfrxjzawdeo]") ~= nil
            end,
        }


    },
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

- Khuyến khích mọi người tắt luôn ime hệ thống cho cửa sỗ terminal để có trải nghiẻm tót nhất.

## 🧩 Phát triển & Góp ý

Rất hoan nghênh issue & pull request! Bạn có thể:

- Báo lỗi logic xử lý dấu hoặc tương thích IME.
- Gợi ý hỗ trợ thêm IME khác hoặc method mới.
- Xin thêm API hoặc thiết lập linh hoạt hơn.

---

## 📄 Giấy phép

Được phát hành với giấy phép **Apache Licence 2.0** – xem file [LICENSE](LICENSE)
