import sys
import os
try:
    import uvicorn
    with open("env_status.txt", "w") as f:
        f.write("uvicorn found\n")
        f.write(str(uvicorn.__file__))
except ImportError:
    with open("env_status.txt", "w") as f:
        f.write("uvicorn NOT found\n")
        f.write(str(sys.executable))
