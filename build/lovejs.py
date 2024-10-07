import sys
import os

os.system("love.js -c -t {0} {1}/love/{0}.love {1}/web".format(sys.argv[1], sys.argv[2]))

# Read in the file
with open(sys.argv[2] + "/web/index.html", 'r') as file :
  filedata = file.read()

# Replace the target string
filedata = filedata.replace('{LOADING_WIDTH}', sys.argv[3])
filedata = filedata.replace('{LOADING_HEIGHT}', sys.argv[4])

# Write the file out again
with open(sys.argv[2] + "/web/index.html", 'w') as file:
  file.write(filedata)