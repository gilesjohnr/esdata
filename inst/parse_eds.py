#%%
import sys
import os
import glob
import zipfile
import shutil

#path_in = "/Users/johngiles/test"
#path_out = "/Users/johngiles/test/out"

path_in = sys.argv[1]
path_out = sys.argv[2]

# Ensure all dirs exist
if not os.path.exists(path_in):
    print("Input path does not exist")
    sys.exit(1)

if not os.path.exists(path_out):
    os.makedirs(path_out)

print(path_in)
print(path_out)

eds_files = glob.glob(os.path.join(path_in, "*.eds"))
print(eds_files)


#%%

# Save copy of .eds files as .zip files
for file in eds_files:

    zip_file = os.path.basename(file)[:-4] + ".zip"
    zip_file_path = os.path.join(path_out, zip_file)
    print(zip_file_path)

    try:
        shutil.copy(file, zip_file_path)
    except Exception as e:
        print(f"An error occurred: {str(e)}")


# %%

# Extract all contents of .zip files
zip_files = glob.glob(os.path.join(path_out, "*.zip"))
print(zip_files)

for file in zip_files:

    path_extracted = os.path.join(path_out, os.path.basename(file)[:-4])

    if not os.path.exists(path_extracted):
        os.makedirs(path_extracted)

    eds_extracted = zipfile.ZipFile(file) 
    eds_extracted.extractall(path_extracted)
    eds_extracted.close()


# %%

# Clean up .zip files
for file in zip_files:
    if os.path.exists(file):
        os.remove(file)

# %%
