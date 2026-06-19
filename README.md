# KAITUN SETUP - All In One

## Chạy 1 lệnh duy nhất trong CMD (Run as Administrator):

```
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://raw.githubusercontent.com/TuanDarcy/file-install/main/setup.bat' -OutFile \"%TEMP%\kaitun_setup.bat\" -UseBasicParsing; Start-Process \"%TEMP%\kaitun_setup.bat\" -Verb RunAs"
```

## Lệnh sẽ tự động:

1. Hỏi FarmSync Key ngay đầu (nếu chưa cài FarmSync)
2. Đồng bộ giờ với `time.cloudflare.com`
3. Set Virtual RAM 350GB (tắt AutoManaged + ghi Registry)
4. Check CuongBoots — bỏ qua nếu đã cài
5. Check + Download `OptimizerRoblox.exe` ra Desktop (có check version, tự update nếu có bản mới)
   - Kill process cũ nếu đang chạy → mở lại bản mới nhất với quyền Admin
   - Thêm vào Startup (tự bật khi khởi động máy)
6. Check `volt.exe` ra Desktop — bỏ qua nếu đã có
7. FarmSync — bỏ qua nếu folder `Desktop\FarmSync` đã tồn tại
   - Cài trong cửa sổ riêng (không block các bước khác)
   - Tự detect khi cài xong → mở `FarmSync_AutoStart` (bỏ qua nếu đã đang chạy)
