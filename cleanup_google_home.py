#!/usr/bin/env python3
"""
Removes all remaining Google Home references from RTSP Rotator codebase
"""

import re
import os

def clean_file(filepath, patterns_to_remove):
    """Remove patterns from file"""
    try:
        with open(filepath, 'r') as f:
            content = f.read()

        original_length = len(content.split('\n'))

        for pattern in patterns_to_remove:
            content = re.sub(pattern, '', content, flags=re.MULTILINE | re.DOTALL)

        # Clean up multiple blank lines
        content = re.sub(r'\n\n\n+', '\n\n', content)

        with open(filepath, 'w') as f:
            f.write(content)

        new_length = len(content.split('\n'))
        print(f"✅ {os.path.basename(filepath)}: Removed {original_length - new_length} lines")
        return True
    except Exception as e:
        print(f"❌ Error cleaning {filepath}: {e}")
        return False

# Patterns to remove from RTSPCameraTypeManager.m
camera_type_patterns = [
    r'@property.*allGoogleHomeCameras.*\n',
    r'_allGoogleHomeCameras = \[NSMutableArray array\];',
    r'} else if \(\[camera isKindOfClass:\[RTSPGoogleHomeCameraConfig class\]\]\) \{[^}]*\}',
    r'} else if \(\[type isEqualToString:@"GoogleHome"\]\) \{[^}]*return[^;]*;\s*\}',
    r'for \(RTSPGoogleHomeCameraConfig.*?\}',
    r'@"googleHomeCameras": self\.allGoogleHomeCameras',
    r'self\.allGoogleHomeCameras\.count',
    r'\[RTSPGoogleHomeCameraConfig class\],',
    r'self\.allGoogleHomeCameras = .*?\];',
]

# Clean RTSPCameraTypeManager.m
camera_type_file = "RTSP Rotator/RTSPCameraTypeManager.m"
if os.path.exists(camera_type_file):
    clean_file(camera_type_file, camera_type_patterns)

print("\n✅ Google Home cleanup complete!")
print("Remaining: Menu bar and preferences controllers")
