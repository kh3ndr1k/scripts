# Python scripts

## fix-ext

A simple script that fixes the extensions of multimedia files, documents, and others. It cat specify one or multiple
filess in a list or a directory. It can also use `DryRun` mode before applying name changes to see how the changes
will be applied.

**NOTE**

The script requieres the `python-magic` and `coloredlogs` modules, which can be installed with pip.

#### **use**

```bash
# exemple of usage with files
$ python3 fix-ext.py --files ~/File_1.jpg ~/File_2.png

# exemple of usage with a directory
$ python3 fix-ext.py --directory ~/Directory/

# for more information, use --help
$ python3 fix-ext.py --help
```

## scanndf

The script scans a directory (first level) and checks for duplicate files, otherwise, You can use the `-r` option to delete
duplicate files, If you want to use secure deletion, you can use the `-R` option, this only works if the `shred` command is 
installed

#### **use**

```bash
# exemple of usage with a directory
$ python3 scanndf.py --dpath ~/Directory/

# for more information, use --help
$ python3 scanndf.py --help
```

