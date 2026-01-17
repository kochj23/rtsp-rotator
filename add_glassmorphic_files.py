#!/usr/bin/env python3
"""
Add RTSPGlassmorphicBackgroundView files to RTSP Rotator Xcode project.
"""

import re
import uuid
import sys

def generate_uuid():
    """Generate a UUID for Xcode (24 hex characters)."""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_project(project_path):
    """Add the glassmorphic background files to the Xcode project."""

    with open(project_path, 'r') as f:
        content = f.read()

    # Generate UUIDs for the new files
    h_file_ref = generate_uuid()
    m_file_ref = generate_uuid()
    h_build_file = generate_uuid()
    m_build_file = generate_uuid()

    # Find the PBXBuildFile section
    build_file_section = re.search(r'(/\* Begin PBXBuildFile section \*/.*?/\* End PBXBuildFile section \*/)', content, re.DOTALL)
    if build_file_section:
        build_file_content = build_file_section.group(1)

        # Add new build files after the Begin marker
        new_build_files = f"""/* Begin PBXBuildFile section */
\t\t{h_build_file} /* RTSPGlassmorphicBackgroundView.h in Headers */ = {{isa = PBXBuildFile; fileRef = {h_file_ref} /* RTSPGlassmorphicBackgroundView.h */; }};
\t\t{m_build_file} /* RTSPGlassmorphicBackgroundView.m in Sources */ = {{isa = PBXBuildFile; fileRef = {m_file_ref} /* RTSPGlassmorphicBackgroundView.m */; }};
"""
        content = content.replace('/* Begin PBXBuildFile section */', new_build_files, 1)

    # Find the PBXFileReference section
    file_ref_section = re.search(r'(/\* Begin PBXFileReference section \*/.*?/\* End PBXFileReference section \*/)', content, re.DOTALL)
    if file_ref_section:
        new_file_refs = f"""/* Begin PBXFileReference section */
\t\t{h_file_ref} /* RTSPGlassmorphicBackgroundView.h */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.h; path = RTSPGlassmorphicBackgroundView.h; sourceTree = "<group>"; }};
\t\t{m_file_ref} /* RTSPGlassmorphicBackgroundView.m */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = RTSPGlassmorphicBackgroundView.m; sourceTree = "<group>"; }};
"""
        content = content.replace('/* Begin PBXFileReference section */', new_file_refs, 1)

    # Find the main group (RTSP Rotator folder) and add file references
    # Look for the RTSP Rotator group with its children
    rtsp_rotator_group = re.search(r'([A-F0-9]{24}) /\* RTSP Rotator \*/ = \{[^}]*?children = \((.*?)\);', content, re.DOTALL)
    if rtsp_rotator_group:
        group_uuid = rtsp_rotator_group.group(1)
        children_content = rtsp_rotator_group.group(2)

        # Add new file references to the children
        new_children = f"""{children_content.rstrip()}
\t\t\t\t{h_file_ref} /* RTSPGlassmorphicBackgroundView.h */,
\t\t\t\t{m_file_ref} /* RTSPGlassmorphicBackgroundView.m */,
"""

        content = content.replace(
            f'children = ({children_content});',
            f'children = ({new_children});',
            1
        )

    # Find the PBXSourcesBuildPhase section and add the .m file
    sources_phase = re.search(r'(/\* Begin PBXSourcesBuildPhase section \*/.*?files = \((.*?)\);)', content, re.DOTALL)
    if sources_phase:
        files_content = sources_phase.group(2)
        new_files = f"""{files_content.rstrip()}
\t\t\t\t{m_build_file} /* RTSPGlassmorphicBackgroundView.m in Sources */,
"""
        content = content.replace(
            f'files = ({files_content});',
            f'files = ({new_files});',
            1
        )

    # Write the modified content back
    with open(project_path, 'w') as f:
        f.write(content)

    print(f"✓ Added RTSPGlassmorphicBackgroundView files to Xcode project")
    print(f"  - Header file reference: {h_file_ref}")
    print(f"  - Implementation file reference: {m_file_ref}")
    print(f"  - Header build file: {h_build_file}")
    print(f"  - Implementation build file: {m_build_file}")

if __name__ == '__main__':
    project_path = '/Volumes/Data/xcode/RTSP Rotator/RTSP Rotator.xcodeproj/project.pbxproj'
    try:
        add_files_to_project(project_path)
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
