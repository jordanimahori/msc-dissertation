# This file contains helper functions and a class used in export_images.py for generating cloud-free mosaics from
# Landsat imagery, creating patches corresponding to layers of cells surrounding each large-scale land acquisition, and
# exporting the patches in TFRecord format.

# Acknowledgements: The class and functions in this script were primarily written by Christopher Yeh and colleagues
# for their paper, Yeh et al. (2020). The original code has been (lightly) adapted here for exporting image patches
# for the locations and years required for my dissertation.


# ==================== HELPER FUNCTIONS =======================

import ee
from typing import Optional


def decode_qamask(img: ee.Image) -> ee.Image:
    """
    Args
    - img: ee.Image, Landsat 5/7/8 image containing 'pixel_qa' band

    Returns
    - masks: ee.Image, contains 5 bands of masks

    Pixel QA Bit Flags (universal across Landsat 5/7/8)
    Bit  Attribute
    0    Fill
    1    Clear
    2    Water
    3    Cloud Shadow
    4    Snow
    5    Cloud
    """
    qa = img.select('pixel_qa')
    clear = qa.bitwiseAnd(2).neq(0)  # 0 = not clear, 1 = clear
    clear = clear.updateMask(clear).rename(['pxqa_clear'])

    water = qa.bitwiseAnd(4).neq(0)  # 0 = not water, 1 = water
    water = water.updateMask(water).rename(['pxqa_water'])

    cloud_shadow = qa.bitwiseAnd(8).eq(0)  # 0 = shadow, 1 = not shadow
    cloud_shadow = cloud_shadow.updateMask(cloud_shadow).rename(['pxqa_cloudshadow'])

    snow = qa.bitwiseAnd(16).eq(0)  # 0 = snow, 1 = not snow
    snow = snow.updateMask(snow).rename(['pxqa_snow'])

    cloud = qa.bitwiseAnd(32).eq(0)  # 0 = cloud, 1 = not cloud
    cloud = cloud.updateMask(cloud).rename(['pxqa_cloud'])

    masks = ee.Image.cat([clear, water, cloud_shadow, snow, cloud])
    return masks


def mask_qaclear(img: ee.Image) -> ee.Image:
    """
    Args
    - img: ee.Image, Landsat 5/7/8 image containing 'pixel_qa' band

    Returns
    - img: ee.Image, input image with cloud-shadow, snow, cloud, and unclear
        pixels masked out
    """
    qam = decode_qamask(img)
    cloudshadow_mask = qam.select('pxqa_cloudshadow')
    snow_mask = qam.select('pxqa_snow')
    cloud_mask = qam.select('pxqa_cloud')
    return img.updateMask(cloudshadow_mask).updateMask(snow_mask).updateMask(cloud_mask)


def add_latlon(img: ee.Image) -> ee.Image:
    """
    Creates a new ee.Image with 2 added bands of longitude and latitude
    coordinates named 'LON' and 'LAT', respectively.
    """
    latlon = ee.Image.pixelLonLat().select(
        opt_selectors=['longitude', 'latitude'],
        opt_names=['LON', 'LAT'])
    return img.addBands(latlon)


def sample_patch(point: ee.Feature, patches_array: ee.Image,
                 scale: float) -> ee.Feature:
    """
    Extracts an image patch at a specific point.

    Args
    - point: ee.Feature
    - patches_array: ee.Image, Array Image
    - scale: int or float, scale in meters of the projection to sample in

    Returns: ee.Feature, 1 property per band from the input image
    """
    arrays_samples = patches_array.sample(
        region=point.geometry(),
        scale=scale,
        projection='EPSG:3857',
        factor=None,
        numPixels=None,
        dropNulls=False,
        tileScale=12)
    return arrays_samples.first().copyProperties(point)


def get_array_patches(img: ee.Image,
                      scale: float,
                      ksize: float,
                      points: ee.FeatureCollection,
                      export: str,
                      prefix: str,
                      fname: str,
                      bucket: str,
                      selectors: Optional[ee.List] = None,
                      dropselectors: Optional[ee.List] = None,
                      ) -> ee.batch.Task:
    """
    Creates and starts a task to export square image patches in TFRecord
    format to Google Cloud Storage (GCS). The image patches are
    sampled from the given ee.Image at specific coordinates.

    Args
    - img: ee.Image, image covering the entire region of interest
    - scale: int or float, scale in meters of the projection to sample in
    - ksize: int or float, radius of square image patch
    - points: ee.FeatureCollection, coordinates from which to sample patches
    - export: 'gcs' for GCS
    - prefix: str, folder name in GCS to export to, no trailing '/'
    - fname: str, filename for export
    - selectors: None or ee.List, names of properties to include in output,
        set to None to include all properties
    - dropselectors: None or ee.List, names of properties to exclude
    - bucket: name of GCS bucket

    Returns: ee.batch.Task
    """
    kern = ee.Kernel.square(radius=ksize, units='pixels')
    patches_array = img.neighborhoodToArray(kern)

    # ee.Image.sampleRegions() does not cut it for larger collections,
    # using mapped sample instead
    samples = points.map(lambda pt: sample_patch(pt, patches_array, scale))

    # export to a TFRecord file which can be loaded directly in TensorFlow
    return tfexporter(collection=samples, export=export, prefix=prefix,
                      fname=fname, selectors=selectors,
                      dropselectors=dropselectors, bucket=bucket)


def tfexporter(collection: ee.FeatureCollection, export: str, prefix: str,
               fname: str, selectors: Optional[ee.List] = None,
               dropselectors: Optional[ee.List] = None,
               bucket: Optional[str] = None) -> ee.batch.Task:
    """
    Creates and starts a task to export a ee.FeatureCollection to a TFRecord
    file in Google Drive or Google Cloud Storage (GCS).

    GCS:   gs://bucket/prefix/fname.tfrecord
    Drive: prefix/fname.tfrecord

    Args
    - collection: ee.FeatureCollection
    - export: str, 'drive' for Drive, 'gcs' for GCS
    - prefix: str, folder name in Drive or GCS to export to, no trailing '/'
    - fname: str, filename
    - selectors: None or ee.List of str, names of properties to include in
        output, set to None to include all properties
    - dropselectors: None or ee.List of str, names of properties to exclude
    - bucket: None or str, name of GCS bucket, only used if export=='gcs'

    Returns
    - task: ee.batch.Task
    """
    if dropselectors is not None:
        if selectors is None:
            selectors = collection.first().propertyNames()

        selectors = selectors.removeAll(dropselectors)

    if export == 'gcs':
        task = ee.batch.Export.table.toCloudStorage(
            collection=collection,
            description=fname,
            bucket=bucket,
            fileNamePrefix=f'{prefix}/{fname}',
            fileFormat='TFRecord',
            selectors=selectors)

    elif export == 'drive':
        task = ee.batch.Export.table.toDrive(
            collection=collection,
            description=fname,
            folder=prefix,
            fileNamePrefix=fname,
            fileFormat='TFRecord',
            selectors=selectors)

    else:
        raise ValueError(f'export "{export}" is not one of ["gcs", "drive"]')

    task.start()
    return task


# ===================== SATELLITE IMAGERY CLASS =======================
# This class abstracts interacting with Google Earth collections for Landsat 5, 7 and 8 imagery. It also renames each
# band and applies transformations to the imagery to ensure consistency with Yeh et al. (2020).


class LandsatSR:
    def __init__(self, filter_polygon: ee.Geometry.Polygon, start_date: str,
                 end_date: str) -> None:
        """
        Args
        - filter_polygon: ee.Geometry
        - start_date: str, string representation of start date
        - end_date: str, string representation of end date
        """
        self.filter_polygon = filter_polygon
        self.start_date = start_date
        self.end_date = end_date

        self.l8 = self.init_col('LANDSAT/LC08/C01/T1_SR').map(self.rename_l8).map(self.rescale_l8)
        self.l7 = self.init_col('LANDSAT/LE07/C01/T1_SR').map(self.rename_l57).map(self.rescale_l57)
        self.l5 = self.init_col('LANDSAT/LT05/C01/T1_SR').map(self.rename_l57).map(self.rescale_l57)

        self.merged = self.l5.merge(self.l7).merge(self.l8).sort('system:time_start')

    def init_col(self, name: str) -> ee.ImageCollection:
        """
        Creates an ee.ImageCollection containing all images intersecting
        the bounding box between the specified start and end dates.

        Args
        - name: str, name of collection

        Returns:
        - ee.ImageCollection
        """
        return (ee.ImageCollection(name)
                .filterBounds(self.filter_polygon)
                .filterDate(self.start_date, self.end_date))

    @staticmethod
    def rename_l8(img: ee.Image) -> ee.Image:
        """
        Args
        - img: ee.Image, Landsat 8 image

        Returns
        - img: ee.Image, with bands renamed for consistency with Yeh et al. (2020)

        See: https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC08_C01_T1_SR

        Name       Scale Factor Description
        B1         0.0001       Band 1 (Ultra Blue) surface reflectance, 0.435-0.451 um
        B2         0.0001       Band 2 (Blue) surface reflectance, 0.452-0.512 um
        B3         0.0001       Band 3 (Green) surface reflectance, 0.533-0.590 um
        B4         0.0001       Band 4 (Red) surface reflectance, 0.636-0.673 um
        B5         0.0001       Band 5 (Near Infrared) surface reflectance, 0.851-0.879 um
        B6         0.0001       Band 6 (Shortwave Infrared 1) surface reflectance, 1.566-1.651 um
        B7         0.0001       Band 7 (Shortwave Infrared 2) surface reflectance, 2.107-2.294 um
        B10        0.1          Band 10 brightness temperature (Kelvin), 10.60-11.19 um
        B11        0.1          Band 11 brightness temperature (Kelvin), 11.50-12.51 um
        sr_aerosol              Aerosol attributes, see Aerosol QA table
        pixel_qa                Pixel quality attributes, see Pixel QA table
        radsat_qa               Radiometric saturation QA, see Radsat QA table
        """
        new_names = ['AEROS', 'BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2',
                     'TEMP1', 'TEMP2', 'sr_aerosol', 'pixel_qa', 'radsat_qa']
        return img.rename(new_names)

    @staticmethod
    def rescale_l8(img: ee.Image) -> ee.Image:
        """
        Args
        - img: ee.Image, Landsat 8 image, with bands already renamed
            by rename_l8()

        Returns
        - img: ee.Image, with bands rescaled
        """
        opt = img.select(['AEROS', 'BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2'])
        therm = img.select(['TEMP1', 'TEMP2'])
        masks = img.select(['sr_aerosol', 'pixel_qa', 'radsat_qa'])

        opt = opt.multiply(0.0001)
        therm = therm.multiply(0.1)

        scaled = ee.Image.cat([opt, therm, masks]).copyProperties(img)
        # system properties are not copied
        scaled = scaled.set('system:time_start', img.get('system:time_start'))
        return scaled

    @staticmethod
    def rename_l57(img: ee.Image) -> ee.Image:
        """
        Args
        - img: ee.Image, Landsat 5/7 image

        Returns
        - img: ee.Image, with bands renamed

        See: https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LT05_C01_T1_SR
             https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LE07_C01_T1_SR

        Name             Scale Factor Description
        B1               0.0001       Band 1 (blue) surface reflectance, 0.45-0.52 um
        B2               0.0001       Band 2 (green) surface reflectance, 0.52-0.60 um
        B3               0.0001       Band 3 (red) surface reflectance, 0.63-0.69 um
        B4               0.0001       Band 4 (near infrared) surface reflectance, 0.77-0.90 um
        B5               0.0001       Band 5 (shortwave infrared 1) surface reflectance, 1.55-1.75 um
        B6               0.1          Band 6 brightness temperature (Kelvin), 10.40-12.50 um
        B7               0.0001       Band 7 (shortwave infrared 2) surface reflectance, 2.08-2.35 um
        sr_atmos_opacity 0.001        Atmospheric opacity; < 0.1 = clear; 0.1 - 0.3 = average; > 0.3 = hazy
        sr_cloud_qa                   Cloud quality attributes, see SR Cloud QA table. Note:
                                          pixel_qa is likely to present more accurate results
                                          than sr_cloud_qa for cloud masking. See page 14 in
                                          the LEDAPS product guide.
        pixel_qa                      Pixel quality attributes generated from the CFMASK algorithm,
                                          see Pixel QA table
        radsat_qa                     Radiometric saturation QA, see Radiometric Saturation QA table
        """
        new_names = ['BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'TEMP1', 'SWIR2',
                     'sr_atmos_opacity', 'sr_cloud_qa', 'pixel_qa', 'radsat_qa']
        return img.rename(new_names)

    @staticmethod
    def rescale_l57(img: ee.Image) -> ee.Image:
        """
        Args
        - img: ee.Image, Landsat 5/7 image, with bands already renamed
            by rename_157()

        Returns
        - img: ee.Image, with bands rescaled
        """
        opt = img.select(['BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2'])
        atmos = img.select(['sr_atmos_opacity'])
        therm = img.select(['TEMP1'])
        masks = img.select(['sr_cloud_qa', 'pixel_qa', 'radsat_qa'])

        opt = opt.multiply(0.0001)
        atmos = atmos.multiply(0.001)
        therm = therm.multiply(0.1)

        scaled = ee.Image.cat([opt, therm, masks, atmos]).copyProperties(img)
        # system properties are not copied
        scaled = scaled.set('system:time_start', img.get('system:time_start'))
        return scaled
