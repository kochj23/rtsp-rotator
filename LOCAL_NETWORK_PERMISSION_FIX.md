# Local Network Permission - The Final Issue! 🔐
## macOS Blocking App Network Access

**Date**: October 30, 2025
**Root Cause**: macOS Local Network Privacy restriction
**Error**: "No route to host" when accessing 192.168.1.9
**Solution**: Grant local network permission

---

## 🚨 **THE ACTUAL PROBLEM**

```
FFmpeg Error: "No route to host" to 192.168.1.9:7441
From Terminal: ✅ FFmpeg works
From App: ❌ Blocked by macOS

Cause: macOS Catalina+ Local Network Privacy
App needs explicit permission to access local network
```

---

## ✅ **THE FIX - GRANT PERMISSION**

### **Check Current Permission:**

1. **System Settings** (or System Preferences)
2. **Privacy & Security** → **Local Network**
3. **Find "RTSP Rotator"** in the list
4. **Make sure it's ENABLED** (checkbox checked)

### **If Not Listed:**

The app needs to trigger the permission dialog first.

---

## 🔧 **TRIGGER PERMISSION DIALOG**

The app should automatically request permission when it tries to access local network. But if dialog didn't appear:

1. **Kill the app**
2. **Delete from Local Network list** (if present)
3. **Restart app**
4. **Permission dialog should appear**
5. **Click "Allow"**

OR run this command:
```bash
sudo tccutil reset Network DisneyGPT.RTSP-Rotator
```

---

## 🧪 **VERIFY NETWORK ACCESS**

### **Test from App:**

The UniFi authentication works (uses curl), so app HAS some network access. But FFmpeg child processes might need explicit permission.

### **Solution: Request Permission Programmatically**

Add code to trigger permission dialog...

---

**Check System Settings → Privacy → Local Network for "RTSP Rotator"!**
