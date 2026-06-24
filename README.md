# KAITUN SETUP - All In One

## Chạy 1 lệnh duy nhất trong CMD (Run as Administrator)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://raw.githubusercontent.com/TuanDarcy/file-install/main/setup.bat' -OutFile \"%TEMP%\kaitun_setup.bat\" -UseBasicParsing; Start-Process \"%TEMP%\kaitun_setup.bat\" -Verb RunAs"
```

## Setup sẽ tự động

1. Hỏi FarmSync Key ngay đầu nếu chưa có FarmSync trên Desktop.
2. Đồng bộ giờ với `time.cloudflare.com`.
3. Set Virtual RAM 350GB qua Registry (tắt AutoManaged + set PagingFiles).
4. Cài CuongBoots nếu chưa có.
5. Thêm AutoRunBoots vào Startup nếu tìm thấy file trong `C:\Tool_Boots`.
6. Kiểm tra `Downloads\OptimizerRoblox` theo thứ tự: đủ file bắt buộc -> đúng version từ Git.
7. Nếu đủ file + đúng version thì skip tải; nếu thiếu file hoặc lệch version thì tải gói `OptimizerRoblox_onedir.zip`, giải nén và cập nhật lại.
8. Kill bản Optimizer cũ và mở lại bản mới với quyền Admin.
9. Thêm Optimizer vào Startup (chỉ dọn shortcut cũ của Optimizer, không đụng app khác).
10. Tải `volt.exe` ra Desktop nếu thiếu.
11. Tải folder `24122024` ra Desktop với đủ file bên trong.
12. Tải hoặc update `MachineMonitor.exe` ra Desktop.
13. Tạo `MachineMonitor.lnk` trong Startup để monitor tự chạy cùng máy.
14. Cài FarmSync trong cửa sổ riêng và tự mở FarmSync_AutoStart khi cài xong.
15. Gửi webhook xác nhận setup hoàn tất:
    - Tự đọc title FarmSync để lấy `Device XX`.
    - Nếu chưa thấy title Device thì tự chạy `FarmSync_AutoStart*.bat` và đợi detect.
    - Gọi API devices để map ra `device_note`.
    - Gửi Discord webhook kèm tên máy, device, note và title.

## MachineMonitor (bot theo dõi riêng)

MachineMonitor là app riêng, không nhúng trong Optimizer.

Hành vi hiện tại:

1. Chỉ gửi alert khi số tab Roblox giảm đột ngột (không gửi heartbeat định kỳ).
2. Alert có ảnh chụp màn hình máy.
3. Đọc title FarmSync để lấy Device (ví dụ `Device 22`).
4. Gọi API FarmSync để map sang note máy và gửi kèm vào alert.
5. Setup script cũng có webhook cuối để báo máy đã cài xong (khác với alert sự cố của monitor).

## Cấu hình MachineMonitor

File cấu hình nằm ở Desktop sau khi setup chạy:

- `MachineMonitor_config.json`

Các trường quan trọng:

1. `webhook_url`: Discord webhook nhận cảnh báo.
2. `farmsync_api_key`: token API (JWT hoặc key FarmSync).
3. `farmsync_devices_url`: mặc định `https://api.farmsync.cloud/api/devices/`.
4. `farmsync_api_key_header`: mặc định `Authorization`.
5. `farmsync_device_id_field`: mặc định `device_name`.
6. `farmsync_note_field`: mặc định `device_note`.

Ghi chú: nếu dùng `Authorization`, monitor sẽ tự thêm tiền tố `Bearer` khi cần.

## Lưu ý quan trọng

1. Không commit webhook hoặc token thật lên GitHub.
2. Nếu repo chuyển sang private, link raw công khai trong `setup.bat` sẽ không tải được trên máy khác.
3. File `OptimizerRoblox_onedir.zip` trong Downloads chỉ là file tạm để giải nén; setup sẽ tự xóa ở cuối bước Optimizer. Nếu setup bị dừng giữa chừng, file này có thể còn lại và lần chạy sau sẽ tự ghi đè/tải lại.
