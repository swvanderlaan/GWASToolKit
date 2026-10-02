"""
Allows running the command-line interface as `python -m gwastoolkit`.

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import sys

from gwastoolkit.cli import main

if __name__ == "__main__":
    sys.exit(main())
