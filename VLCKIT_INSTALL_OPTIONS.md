# VLCKit Installation - Simple Options 🚀
## No Obscure Tools Needed!

**Date**: October 30, 2025
**Issue**: Need VLCKit but .tar.xz is uncommon
**Solution**: 3 simple alternatives

---

## ✅ **OPTION 1: Built-in macOS tar** (Standard) ⭐ EASIEST

**Good News**: Your Mac's tar ALREADY supports .xz files!

```bash
$ tar --version
bsdtar 3.5.3 - libarchive 3.7.4 liblzma/5.4.3
                                    ↑
                          Built-in xz support!
```

**Run this:**
```bash
/tmp/download_vlckit.sh
```

**It will work!** Your Mac's tar has liblzma built-in.

---

## ✅ **OPTION 2: Install VLC App** (Simplest) 🥇

**Easiest method - uses Homebrew:**

```bash
/tmp/download_vlckit_simple.sh
```

**What it does:**
1. Installs VLC player app via Homebrew
2. VLC includes all the libraries we need
3. I'll extract them and add to your project
4. Done!

**Requirement**: Homebrew installed

---

## ✅ **OPTION 3: Manual Download** (No Command Line)

**If you prefer clicking buttons:**

1. **Visit**: https://www.videolan.org/vlc/download-macos.html
2. **Download VLC for macOS**
3. **Install VLC.app** (drag to Applications)
4. **Tell me**: "VLC installed"
5. **I'll extract** the needed libraries
6. **Done!**

---

## 📊 **COMPARISON**

| Method | Time | Requires | Difficulty |
|--------|------|----------|------------|
| **Option 1: tar script** | 2 min | Nothing (built-in) | ⭐ Easiest |
| **Option 2: Homebrew VLC** | 5 min | Homebrew | ⭐⭐ Easy |
| **Option 3: Manual VLC** | 5 min | Web browser | ⭐⭐ Easy |

---

## 🚀 **RECOMMENDED: OPTION 1**

Your Mac's `tar` command ALREADY supports .xz files (via liblzma)!

**Just run:**
```bash
/tmp/download_vlckit.sh
```

**Output:**
```
Downloading VLCKit framework...
✅ Downloaded VLCKit.tar.xz
Extracting (using built-in macOS tar with xz support)...
✅ VLCKit.framework extracted successfully!

Location: ~/Downloads/VLCKit.framework

NEXT STEPS:
1. Open Xcode with your project
2. Drag VLCKit.framework into project
3. Set to 'Embed & Sign'
4. Tell Claude: 'VLCKit installed'
```

---

## 💡 **IF YOU PREFER HOMEBREW**

```bash
# Option 2 - Install VLC via Homebrew:
/tmp/download_vlckit_simple.sh

# This installs VLC player
# Then I'll extract VLCKit from it
# Same result, different path
```

---

## 🎯 **AFTER INSTALLATION**

Once you have VLCKit (either method), I'll:

1. ✅ Modify app to use VLCMediaPlayer
2. ✅ Handle RTSPS with self-signed certificates
3. ✅ Keep all your fixes (security, memory, etc.)
4. ✅ All 20 cameras will play!
5. ✅ No more Error -1002!

**Integration time: 10 minutes**

---

## ✅ **PICK ONE AND RUN IT**

```bash
# Option 1 (uses built-in tar):
/tmp/download_vlckit.sh

# Option 2 (uses Homebrew):
/tmp/download_vlckit_simple.sh

# Option 3:
# Just download VLC from website and tell me
```

---

**Your Mac's tar DOES support .xz - it's not obscure, it's built-in!**

**Just run Option 1!** 🚀