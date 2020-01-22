# Plugin Showing Oxygen Change Tracking information in the PDF output
Plugin which allows showing Oxygen track changes and comments, and change bars, in the classic PDF output obtained using the DITA-OT.
The plugin is compatible and was tested with DITA-OT 3.x.
The change bars displaying is compatible and was tested with following PDF publishing engine :
* Antenna House 
* FOP 2.4 and later

This plugin does not contribute a new transformation type.

## Parameters
* __show.changes.and.comments__ set to "yes" to enable showing Oxygen track changes and comments in the generated PDF.
* __show.changebars__ set to "yes" to enable change bars, based on Oxygen changes, in the generated PDF.

## Installation
You just need to install it and then run the regular PDF (Idiom) publishing using the PDF plugin bundled with the DITA OT.

Copyright and License
---------------------
Copyright 2018 Syncro Soft SRL.

This project is licensed under [Apache License 2.0](https://github.com/oxygenxml/dita-classic-pdf-review/blob/master/LICENSE)
