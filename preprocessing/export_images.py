
# OVERVIEW:
# We need to extract patches of 255x255 pixels (~7.6km in diameter) from LandSat scenes which are ~115km x 115km in
# area. The centre patch is positioned such that its centroid lies over top of the centroid of the agricultural
# development, and subsequent patches area arranged in a grid emanating outward. For every agricultural development, we
# therefore generate a series of patches around its centroid and export them in TFRecord format so that we can generate
# estimates of household material assets using model weights from Yeh et al. (2020).

# In order to filter Earth Engine image collections to show an area containing at least the centre cell + 2 adjacent
# rings of cells, we need images matching an area of radius ~7.6km x 2.5, or a box of approximately 46km x 46km, centred
# around each industrial agriculture development. This script creates these boxes and generates a file which will be
# used by Earth Engine to create the necessary mosaics.


import ee
import math
import pandas as pd
from utils import ee_utils


# ==================== PARAMETERS ======================

# Export Data Params
EXPORT = 'gcs'          # to export to Google Drive, set as: 'drive'
BUCKET = 'msc-imagery'  # to export to Google Drive, set as: None
EXPORT_FOLDER = 'tfrecords_raw'

# Input Data Path
CSV_PATH = 'data/earthengine_test.csv'

# Band Names
MS_BANDS = ['BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2', 'TEMP1']

# Image Parameters
PROJECTION = 'EPSG:3857'  # see https://epsg.io/3857
SCALE = 30                # export resolution: 30m/px
NRINGS = 0                # number of concentric rings of tiles to export
EXPORT_TILE_RADIUS = 127 + 255*NRINGS  # image dimension = (2*EXPORT_TILE_RADIUS) + 1 = 255px


# =================== INITIALIZE ENVIRONMENT ============================

# Initialize Earth Engine
ee.Initialize()

# Load location candidates
df = pd.read_csv(CSV_PATH)


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
    - start_year: int, determines the starting year of the first block
    - end_year: int, determines the last year (or cutoff) of the last block
    - export_folder: str, sets the folder where exports are sent
    - n: int, sets the number of concentric rings of tiles to be exported (excludes the centroid cell)
    - mosaic_period: int, sets the interval of time, in years, for which each mosaic is created

    Returns:
    - dict of tasks.

    If a date range is supplied that is not a multiple of the mosaic period, the remaining years will be truncated.
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
            # Creates a cloud-free composite from all images intersecting the max_extent polygon within the interval.
            block_start = str(year) + "-01-01"
            block_end = str(year + mosaic_period - 1) + "-12-31"
            image_col = ee_utils.LandsatSR(max_extent, block_start, block_end).merged
            image_col = image_col.map(ee_utils.mask_qaclear).select(MS_BANDS)
            img = image_col.median()
            img = ee_utils.add_latlon(img)   # add latitude and longitude bands

            fname = f'{deal_id}_{year}'
            tasks[(export_folder, deal_id, block_start, i)] = ee_utils.get_array_patches(
                img=img, scale=SCALE, ksize=EXPORT_TILE_RADIUS,
                pt=loc, export=EXPORT, prefix=export_folder,
                fname=fname, bucket=BUCKET)

            year = year + mosaic_period

    return tasks


export_images(df, 2013, 2016, EXPORT_FOLDER, 2, 3)

