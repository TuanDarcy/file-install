# KAITUN SETUP - All In One

## Chạy 1 lệnh duy nhất trong CMD (Run as Administrator)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$u='https://raw.githubusercontent.com/TuanDarcy/file-install/main/setup.bat?ts='+(Get-Date).Ticks; $f=Join-Path $env:TEMP ('kaitun_setup_'+(Get-Random)+'.bat'); Invoke-WebRequest $u -OutFile $f -UseBasicParsing; Start-Process $f -Verb RunAs"
```

Ghi chú: chỉ dùng lệnh trên để tránh cache bản setup cũ.

## Setup sẽ tự động

1. Hỏi FarmSync Key ngay đầu nếu chưa có FarmSync trên Desktop.
2. Đồng bộ giờ với `time.cloudflare.com`.
3. Set Virtual RAM **320GB** qua Registry (tắt AutoManaged + set PagingFiles).
4. Cài CuongBoots nếu chưa có.
5. Thêm AutoRunBoots vào Startup nếu tìm thấy file trong `C:\Tool_Boots`.
6. Kiểm tra `Downloads\OptimizerRoblox` theo thứ tự: đủ file bắt buộc -> đúng version từ Git.
7. Nếu folder `Downloads\OptimizerRoblox` bị thiếu file/dependency thì setup sẽ dừng Optimizer đang chạy, xóa folder lỗi đó và tải lại full `OptimizerRoblox_onedir.zip` để giải nén sạch.
8. Nếu folder đầy đủ nhưng lệch version thì setup ưu tiên cập nhật riêng `OptimizerRoblox.exe`; chỉ fallback zip khi cần.
9. Kill bản Optimizer cũ và mở lại bản mới với quyền Admin.
10. Thêm Optimizer vào Startup (chỉ dọn shortcut cũ của Optimizer, không đụng app khác).
11. Tải `volt.exe` ra Desktop nếu thiếu.
12. Tải folder `24122024` ra Desktop với đủ file bên trong.
13. Cài FarmSync trong cửa sổ riêng và tự mở FarmSync_AutoStart khi cài xong.

## Lưu ý quan trọng

1. Nếu repo chuyển sang private, link raw công khai trong `setup.bat` sẽ không tải được trên máy khác.
2. File `OptimizerRoblox_onedir.zip` trong Downloads chỉ là file tạm để giải nén; setup sẽ tự xóa ở cuối bước Optimizer. Nếu setup bị dừng giữa chừng, file này có thể còn lại và lần chạy sau sẽ tự ghi đè/tải lại.
3. Setup sẽ dọn các file/folder Optimizer cũ trên Desktop trước khi tạo shortcut mới, tránh dùng nhầm bản cũ.
