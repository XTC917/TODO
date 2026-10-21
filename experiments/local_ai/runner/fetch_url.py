import sys
import urllib.request

url = sys.argv[1]
out = sys.argv[2]
print("downloading", url, flush=True)
urllib.request.urlretrieve(url, out)
print("saved", out, flush=True)
