
# OVERVIEW:
# We need to extract patches of 255x255 pixels (~7.6km in diameter) from LandSat scenes which are ~115kmx115km in area.
# The centre patch is positioned such that its centroid lies over top of the centroid of the agricultural development,
# and subsequent patches area arranged in a grid emanating outward. For every agricultural development, we therefore
# generate a series of patches around its centroid and export them in TFRecord format so that we can generate estimates
# of household material assets using model weights from Yeh et al. (2020).

# In order to filter Earth Engine image collections to show an area containing at least the centre cell + 3 adjacent
# rings of cells, we need images matching an area of radius ~6.25x3.5, or a box of approximately 40km x 40km, centred
# around each industrial agriculture development. This script creates these boxes and generates an file which will be
# used by Earth Engine to create the necessary mosaics.

import ee
import math
import pandas as pd
from utils import ee_utils

# Initialize Earth Engine
ee.Initialize()


# Load location candidates
df = pd.read_csv("data/earthengine_locs.csv")


# ==================== PARAMETERS ======================

# Export Data Params
EXPORT = 'gcs'
BUCKET = 'msc-ed-satellite-imagery'
EXPORT_FOLDER = 'af_tfrecords_raw'

# Input Data Path
CSV_PATH = 'data/earthengine_locs.csv'

# Band Names
MS_BANDS = ['BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2', 'TEMP1']

# Image Parameters
PROJECTION = 'EPSG:3857'  # see https://epsg.io/3857
SCALE = 30                # export resolution: 30m/px
EXPORT_TILE_RADIUS = 127  # image dimension = (2*EXPORT_TILE_RADIUS) + 1 = 255px


# ==================== MAIN FUNCTIONS ======================

def export_images(df: pd.DataFrame,
                  start_year: int,
                  end_year: int,
                  export_folder: str,
                  n: int,
                  mosaic_period: int
                  ) -> dict[str, ee.batch.Task]:
    """
    Args:
    - df: pd.Data.Frame containing lat, lon, and deal_id columns
    - start_year: int, determines the first year of blocks
    - end_year: int, determines the last year (or cutoff) of blocks
    - export_folder: str, sets the folder where exports are sent
    - n: int, sets the neighbourhood size in terms of number of "rings" (excludes the centre cell)
    - mp: int, sets the period, in years, over which the mosaics are created

    Returns:
    - dict of tasks.

    If a date range is supplied that is not a multiple of the period length, the remaining years will be truncated.
    The function will attempt to alert the user when this occurs.
    """
    # Estimates generated in blocks according to provided mosaic period.
    num_periods = math.floor((end_year - start_year) / mosaic_period)
    tasks = {}

    for idx, deal_id, lat, lon in df.itertuples():
        loc = ee.Geometry.Point(lon, lat)
        max_extent = loc.buffer(distance=7650*(n + 0.5)).bounds()    # 30m/px * 255pxs
        year = start_year
        for i in range(num_periods):
            # For each period of duration mosaic_period, this creates a cloud-free composite from all images
            # intersecting the max_extent polygon between the supplied years.
            block_start = str(year) + "-01-01"
            block_end = str(year + mosaic_period - 1) + "-12-31"
            year = year + mosaic_period
            image_col = ee_utils.LandsatSR(max_extent, block_start, block_end).merged
            image_col = image_col.map(ee_utils.mask_qaclear).select(MS_BANDS)
            img = image_col.median()
            img = ee_utils.add_latlon(img)

            tasks[(str(deal_id) + "_" + str("{:02d}".format(i)))] = ee_utils.get_array_patches(
            img=img, scale=SCALE, ksize=EXPORT_TILE_RADIUS,
            points=fc, export=EXPORT, prefix=export_folder,
            fname=fname, bucket=BUCKET)
    return tasks


