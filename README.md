markdown_content = """# EXPY — Terminal Finance Tracker

[![Download EXPY APK](https://img.shields.io/badge/Download-EXPY%20APK-brightgreen?style=for-the-badge&logo=android)](https://github.com/GoLu-Jii/EXPY/releases/latest/download/EXPY-V-0.1.0.apk)

EXPY is a 100% offline, terminal-themed personal finance tracker. It allows you to track monthly budgets, categorize spending, manage peer debts (to give / to take) with carry-forward, and maintain a separate savings pocket without needing an internet connection or cloud sync.

## Installation

1. Download the `EXPY-V-0.1.0.apk` using the download button above on your Android device.
2. Tap the downloaded file to install it.
3. If prompted, enable "Allow installation from unknown sources" in your device settings.
"""

with open('README.md', 'w', encoding='utf-8') as f:
    f.write(markdown_content)

print("README.md generated successfully.")