import math
import numpy as np


def get_ring_ids(rings):
    width = (rings*2 + 1)
    ar = np.arange(0, width**2, 1).reshape(width, width)
    ring_dict = {}

    for i in range(math.ceil(width / 2)):
        if math.floor(width / 2) == i:
            items = [ar[i, i].tolist()]
        else:
            items = ar[i, i:(width - i)].tolist() + ar[-(i + 1), i:(width - i)].tolist() + \
                    ar[i:(width - i), i].tolist() + ar[i:(width - i), -(i + 1)].tolist()
        ring_dict[i] = list(set(items))
    return ring_dict
