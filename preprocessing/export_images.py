
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
                  export_folder: str
                  ) -> dict[str, ee.batch.Task]:
    """
    Args:
    - df: pd.Data.Frame containing lat, lon, and deal_id columns
    - start_year: int, determines the first year of blocks
    - end_year: int, determines the last year (or cutoff) of blocks
    - export_folder: str, sets the folder where exports are sent
    """
    # Estimates generated in 3-year blocks.
    periods = int(math.floor(end_year - start_year)/3)
    tasks = {}

    for idx, deal_id, lat, lon in df.itertuples():
        loc = ee.Geometry.Point(lon, lat)
        min_area = loc.buffer(distance=20000).bounds()
        year = start_year
        for i in range(periods):
            block_start = str(year) + "-01-01"
            block_end = str(year + i) + "-12-31"
            year = year + i

            image_col = ee_utils.LandsatSR(min_area, block_start, block_end).merged
            image_col = image_col.map(ee_utils.mask_qaclear).select(MS_BANDS)
            img = image_col.median()
            img = ee_utils.add_latlon(img)

            tasks[deal_id] = ee_utils.get_array_patches() # Fix
    return tasks




start_year = 2000
end_year = 2020


