# Setting up a remote machine

Since the process of generating poverty estimates is relatively computationally and memory intensive, it'll be easiest to do this by setting up a remote machine. Since Google Earth Engine ties in closely with Google Cloud, it'll be easiest to use that. 

Learn more at: 


### Setting up the virtual machine and disk: 

```
gcloud compute instances create msc-machine --machine-type=n2-highmem-4 --image-family=ubuntu-1804-lts --image-project=ubuntu-os-cloud

gcloud compute disks create msc-imagery --size=300 --type=pd-balanced

gcloud compute instances attach-disk msc-machine --disk msc-imagery

```

From the remote machine, first format the disk:

```
# First format the disk: 
# sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb

# Create a mount directory:
# sudo mkdir -p /mnt/disks/msc-imagery

# Mount the disk: 
# sudo mount -o discard,defaults /dev/sdb /mnt/disks/msc-imagery

# Set permissions:
# sudo chmod a+w /mnt/disks/msc-imagery

# Create backup
# sudo cp /etc/fstab /etc/fstab.backup

# Get UUID
# sudo blkid /dev/sdb

# Create entry in /etc/fstab by sudo nano ... and then add: 
# UUID=46af1eb4-466a-44d7-b135-12cbded72259 /mnt/disks/msc-imagery ext4 discard,defaults,nofail 0 2

```

Next, you'll want to clone the contents of the git repository to your machine, and copy the TFRecord files into the /data directory. 

Run: 

```
cd /mnt/disks/msc-imagery/
mkdir Dissertation
git clone https://github.com/jordanimahori/africa_poverty_clean.git

# Copy contents of satellite imagery TFRecords to your local directory
gsutil rsync -r gs://msc-ed-satellite-imagery/ ./africa_poverty_clean/data/

```


