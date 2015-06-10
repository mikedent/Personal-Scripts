# Location of outlook archive .pst file
$pst = "C:\Users\212049965\Documents\Outlook Files\archive.pst"

# Destination of the flashdrive
$dest = "F:\"

# Copying archive pst to flash drive
Copy-Item $pst $dest -Recurse