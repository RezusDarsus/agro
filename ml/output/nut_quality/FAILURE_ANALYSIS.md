# Nut-quality failure analysis

- Test images: **2380** | misclassified views: **124** (single-view accuracy 94.79%).
- After averaging ten views per physical nut, accuracy rises to **98.74%**.
- The `misclassified/` gallery holds the 60 highest-confidence errors (filenames encode true/pred/confidence/nut_id/original).

## Confusion pairs (true -> predicted)

| Pair | Count |
|---|---:|
| damaged_nuts -> quality_nuts | 94 |
| nuts_kernel -> quality_nuts | 19 |
| nuts_kernel -> damaged_nuts | 9 |
| quality_nuts -> damaged_nuts | 2 |

## Main business risk

The dominant error is `damaged_nuts -> quality_nuts`. In single-view mode a damaged nut can occasionally read as a quality nut, so a quality grade should require either a confidence margin or several views (use the app multi-view mode) before a nut is accepted into a quality batch.
