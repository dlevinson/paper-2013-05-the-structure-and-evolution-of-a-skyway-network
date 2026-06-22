# The Structure and Evolution of a Skyway Network

## Contribution

This paper explains how Minneapolis's privately developed skyway system evolved from a tree-like structure into a more connected grid. Empirical network analysis and an agent-based model show how decentralized building-owner incentives, office size, accessibility, and existing centrality shaped both the timing and structure of new connections.

This package contains the paper PDF, the NetLogo model source, and the GIS input files for Huang and Levinson (2013), "The Structure and Evolution of a Skyway Network," European Physical Journal: Special Topics 215(1):123-134. DOI: 10.1140/epjst/e2013-01719-1.

## Contents

- `paper/st215010.pdf`: final/published paper PDF.
- `code/netlogo/NetworkGrowthCom.nlogo`: NetLogo GIS model source. Its header identifies the skyway network paper, and its setup loads the packaged GIS inputs.
- `data/gis/centroids_new2_SpatialJoin6/`: building/block centroid GIS input and office-space attributes used by the model.
- `data/gis/downtown_skyways2/`: observed downtown skyway segment GIS input loaded by the model.
- `data/gis/potentialblocks/`: potential-block geometry loaded by the model to set the GIS envelope.
- `metadata/SOURCE_FILE_DECISIONS.csv`: inclusion/exclusion decisions for the local source folders.
- `PACKAGE_MANIFEST.csv`: package file manifest.

## Running Notes

The model is an older NetLogo model using the NetLogo GIS extension. Runtime JARs and third-party extension files from the local student folder were not copied because they are dependencies rather than paper-authored source data/code. Open `code/netlogo/NetworkGrowthCom.nlogo` in a compatible NetLogo environment with the GIS extension available. If the model is run from outside `code/netlogo/`, update the relative GIS paths or place the three GIS datasets alongside the model.

## Archive Boundary

The source folders contain manuscripts, drafts, editor letters, presentation files, generated figures, and old runtime dependencies. Those are intentionally excluded. The earlier Minneapolis skyway data/source paper, Corbett, Xie, and Levinson (2009), is tracked separately as `paper-2009-01` with a public UMN/DRUM archive pointer, so that full folder is not duplicated here.

## Known Sidecar Repair

Several tiny legacy GIS sidecars in the Arthur Huang folder timed out during direct copy despite appearing in Finder. The model source itself and the main GIS geometry/attribute files were copied. For `potentialblocks`, the model uses the dataset only to set the GIS envelope, so the package keeps the source geometry, reconstructs the shapefile index, fills the projection from the matching local PRJ, and provides a minimal DBF sidecar. This is documented in `PACKAGE_MANIFEST.csv` and `metadata/SOURCE_FILE_DECISIONS.csv`.

<!-- package-hardening-status:start -->
## Package Hardening Status

Generated: 2026-05-21 20:04:48 AEST

- Pipeline: `UPLOADED`
- Sidecars added/updated: `PACKAGE_STATUS.md`, `PACKAGE_MANIFEST.csv`, `LICENSE_STATUS.md`.
- Paper reference copies are for local audit convenience and are not public-upload assets without rights review.
- Final GitHub upload should use the manifest include statuses and the license-status note.
<!-- package-hardening-status:end -->
