# Storage Tracker

A lightweight Flutter app that shows how much storage is used by **Images, Videos, Audio, Documents** and **Other** files on your Android device.

---

## ✅ Features
- No **broad storage permission** (`MANAGE_EXTERNAL_STORAGE`) required  
- Uses **MediaStore-only** approach → Google-Play compliant  
- Auto-switches to **KB / MB / GB**  
- Works from **Android 10 → 14**

---

## 🚀 Build & Run
```bash
git clone https://github.com/Dikshant005/storage-tracker
cd storage_tracker
flutter pub get
flutter run --release
```

## 🔐 Permissions Asked

| Permission | Reason |
|------------|--------|
| `READ_MEDIA_IMAGES` | Count & size of pictures |
| `READ_MEDIA_VIDEO` | Count & size of videos |
| `READ_MEDIA_AUDIO` | Count & size of music |
| `READ_EXTERNAL_STORAGE` *(legacy)* | Fallback for Android ≤ 11 |

## 📂 Scan Logic

| Step | What Happens |
|------|--------------|
| 1 | Request narrow media permissions (`READ_MEDIA_*`) at runtime |
| 2 | Walk **only** shared external storage (`/storage/emulated/0`) |
| 3 | Skip **Android/data** & **Android/obb** (scoped-storage protected) |
| 4 | Group files by extension → Images, Videos, Audio, Documents |
| 5 | Sum **count** and **bytes** per group |
| 6 | Other = every remaining file **not** in the four groups above |
| 7 | Convert bytes → KB / MB / GB with one-decimal precision |
